filename = ARGV[0]
$links = Array.new
$pubs = Array.new

class Image
  def initialize(filename)
    @filename = filename
  end

  def emit
    "<img src=\"#{@filename}\" width=504>"  
  end
end

class AsciiImage
  def initialize(filename)
    @filename = filename
  end

  def emit
    `jp2a --fill --colors --chars=@8OCoc:. --width=72 --html-raw #{@filename}`
  end
end


class Paragraph
  def initialize
    @text = ""
  end

  def addline(line)
    @text += line
  end

  def emit

    # look for links 
    loop do
      linked = @text[/\[([^\]]*)\]\[([^\]]*)\]/, 1]
      hrefid = @text[/\[([^\]]*)\]\[([^\]]*)\]/, 2]

      break if linked.nil? || hrefid.nil?

      href = $links.select { |x| x.match(hrefid) }[0].url
      @text = @text.sub(/\[([^\]]*)\]\[([^\]]*)\]/, "<a href=#{href}>#{linked}</a>")
    end

    # look for pubs
    loop do 
      id = @text[/\[\[([^\]]*)\]\]/, 1]
      break if id.nil?

      p = $pubs.select { |x| x.match(id) }[0]
      break if p.nil?
      
      @text = @text.sub(/\[\[([^\]]*)\]\]/, 
                        "[<a href=\"\##{p.object_id}\">#{p.num}</a>]")   
    end

    "<p>" + @text.gsub(/\*([^\*]*)\*/, '<i>\1</i>') + "</p>"
  end
end

class List
  attr_reader :ordered, :paras

  def initialize(ordered)
    @ordered = ordered
    @paras = Array.new
  end

  def addpara(p)
    @paras.push p
  end

  def emit
    str = @ordered ? '<ol>' : '<ul>'
    @paras.each do |p| 
      str += '<li>' + p.emit + '</li>'
    end
    str += @ordered ? '</ol>' : '</ul>'
  end
end

class Subsection
  attr_reader :title, :content

  def initialize(str="")
    @title = str
    @content = Array.new
  end

  def addcontent(c)
    @content.push c
  end

  def emit
    str = '<div class="subsection">'
    str += "<h3><a id=\"#{self.object_id}\">#{@title}</a></h3>"
    @content.each { |c| str += c.emit }
    str += '</div>'
  end
end

class Publication
  attr_reader :num
  @@numpubs = 0

  def initialize(str)
    @id = str[/^\[\[(.*)\]\]: /, 1]
    @url = str.gsub(/^\[\[.*\]\]: /, '')
    @text = ""
    @@numpubs += 1
    @num = @@numpubs
  end

  def addline(line)
    @text += line
  end

  def match(id)
    @id == id
  end

  def emit
    linked = @text[/\[([^\]]*)\]/, 1]
    unless linked.nil?
      @text = @text.sub(/\[([^\]]*)\]/, "<a href=#{@url}>#{linked}</a>")
    end
    str = "<li><p><a id=\"#{self.object_id}\">"
    str += @text + "</a></p></li>"
    str
  end
end

class Link
  attr_reader :url

  def initialize(str)
    @id = str[/^\[(.*)\]: /, 1]
    @url = str.gsub(/^\[.*\]: /, '')
  end

  def match(id)
    @id == id
  end
end

class Section 
  attr_reader :title, :subsections, :leadin

  def initialize(str, toc)
    @toc = toc
    @title = str.gsub(/^===== /, '').gsub(/ =====$/, '')
    @leadin = Subsection.new
    @subsections = Array.new
  end
  
  def addsub(sub)
    @subsections.push sub
  end

  def emit
    str = '<hr>'
    str += '<div class="section">'
    str += "<h2><a id=\"#{self.object_id}\">#{@title}</a></h2>"

    if @toc
      str += '<div class="toc"><ol>'
      @subsections.each do |s| 
        str += "<li><a href=\"\##{s.object_id}\">"
        str += "#{s.title}</a></li>"
      end
      str += '</ol></div>'
    end

    str += @leadin.emit
    @subsections.each { |s| str += s.emit }
    str += '</div>'
  end    
end

sections = []

prevline = ''
cursub = cursec = curp = curl = curpub = nil
inpara = inlist = inpub = false
titlelines = []

File.readlines(filename).each do |line|

  if line.match(/^=====.*=====\|$/) # section header with no toc
    cursec = Section.new(line.sub(/\|$/, ''), false)
    
    # first subsection is the leadin
    cursub = cursec.leadin

    sections.push cursec

  elsif line.match(/^=====.*=====$/) # section header with toc
    cursec = Section.new(line, true)
    
    # first subsection is the leadin
    cursub = cursec.leadin

    sections.push cursec

  elsif line.match(/^---*$/) # subsection underscore

    # previous line had title of subsec
    cursub = Subsection.new(prevline)
    cursec.addsub(cursub) unless cursec.nil?

    # forget the para we started with the subsec title
    inpara = false

  elsif line.match(/^\s*[0-9][0-9]*\. /) # list item

    curl = List.new(true) unless inlist

    # finish off previous para if already in list
    curl.addpara curp if inpara && inlist

    # start a new para for the list entry
    curp = Paragraph.new
    curp.addline(line.gsub(/[0-9][0-9]*\. /, ''))
    inpara = true
    inlist = true

  elsif line.match(/^\s*- /) # list item

    curl = List.new(false) unless inlist

    # finish off previous para if already in list
    curl.addpara curp if inpara && inlist

    # start a new para for the list entry
    curp = Paragraph.new
    curp.addline(line.gsub(/^\s*- /, ''))
    inpara = true
    inlist = true

  elsif line.match(/^#img.*/) # image
    cursub.addcontent(Image.new(line.gsub(/^\#img /,'')))

  elsif line.match(/^#asciiimg.*/) # image
    cursub.addcontent(AsciiImage.new(line.gsub(/^\#asciiimg /,'')))

  elsif line.match(/^\[\[.*\]\]: /) # publication link
    curpub = Publication.new(line.chomp)
    inpub = true
    $pubs.push(curpub)
    
  elsif line.match(/^\[.*\]: /) # link ref
    $links.push(Link.new(line.chomp))

  elsif line.chomp == '' # a blank line

    # done with paragraph or list item
    if inpara && !cursub.nil?
      inlist ? curl.addpara(curp) : cursub.addcontent(curp)
    end

    # could be still working on list, but definitely done with para
    inpara = false
    inpub = false
  else # random line with text

    # if we haven't started sections yet, it's the title
    titlelines.push line if cursub.nil?

    # we might be in a publication
    if inpub
      curpub.addline(line)

    else
      
      # must have had blank line (!inpara) and didn't match number, so
      # we're done with the list now
      if inlist && !inpara
        inlist = false 
        cursub.addcontent curl
      end
      
      # start new para (if we aren't in the middle of one)
      curp = Paragraph.new unless inpara
      
      # start adding to our para
      curp.addline(line)
      inpara = true
    end
  end

  prevline = line
end

html = '<!DOCTYPE html>'
html += '<html lang="en">'
html += '<head>'
html += '<meta name="viewport" content="width=device-width,'
html += '      initial-scale=1 user-scalable=no">'
html += '<style>'
html += 'body {'
html += 'font-family:monospace;'
html += '}'
html += 'h1 {'
html += '}'
html += 'img {'
html += 'max-width:100%'
html += '}'
html += 'p,h2,h3,.toc {'
html += '}'
html += ''
html += '.section {'
html += '}'
html += ''
html += '.content {'
html += 'max-width:504px;'
html += 'white-space:normal;'
html += 'font-family:monospace;'
html += '}'
html += '@media (min-width:560px){'
html += '  .content {'
html += '    padding-left:56px;'
html += '  }'
html += '}'
html += '.green {'
html += 'background-color:#99ff99;'
html += '}'
html += '.red {'
html += 'text-decoration:line-through;'
html += 'background-color:#ff9999;'
html += '}'
html += '</style>'
html += '</head>'
html += '<body>'
html += '<b><pre>'
titlelines.each { |l| html += l }
html += '</pre></b>'
html += '<div class="content">'

html += '<div class="toc"><ol>'
sections.each do |s| 
  html += "<li><a href=\"\##{s.object_id}\">"
  html += "#{s.title}</a></li>"
end
html += '</ol></div>'

sections.each { |s| html += s.emit }

html += '<div class="pubs"><ol>'
$pubs.each { |p| html += p.emit }
html += '</ol></div>'

html += '</div>'
html += ''
html += '</body>'
html += '</html>'

puts html
