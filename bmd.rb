filename = ARGV[0]
$links = Array.new

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
    linked = @text[/\[([^\]]*)\]\[([^\]]*)\]/, 1]
    hrefid = @text[/\[([^\]]*)\]\[([^\]]*)\]/, 2]

    unless linked.nil? || hrefid.nil?
      href = $links.select { |x| x.match(hrefid) }[0].url
      @text = @text.gsub(/\[([^\]]*)\]\[([^\]]*)\]/, "<a href=#{href}>#{linked}</a>")
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

  def initialize(str)
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

    str += '<div class="toc"><ol>'
    @subsections.each do |s| 
      str += "<li><a href=\"\##{s.object_id}\">"
      str += "#{s.title}</a></li>"
    end
    str += '</ol></div>'

    str += @leadin.emit
    @subsections.each { |s| str += s.emit }
    str += '</div>'
  end    
end

sections = []

prevline = ''
cursub = cursec = curp = curl = nil
inpara = inlist = false
titlelines = []

File.readlines(filename).each do |line|

  if line.match(/^=====.*=====$/) # section header
    cursec = Section.new(line)
    
    # first subsection is the leadin
    cursub = cursec.leadin

    sections.push cursec

  elsif line.match(/---*/) # subsection underscore

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

  elsif line.match(/^\[.*\]: /) # link ref
    $links.push(Link.new(line.chomp))

  elsif line.chomp == '' # a blank line

    # done with paragraph or list item
    if inpara && !cursub.nil?
      inlist ? curl.addpara(curp) : cursub.addcontent(curp)
    end

    # could be still working on list, but definitely done with para
    inpara = false

  else # random line with text

    # if we haven't started sections yet, it's the title
    titlelines.push line if cursub.nil?

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

  prevline = line
end

html = '<!DOCTYPE html>'
html += '<html>'
html += '<head>'
html += '<style>'
html += 'body {'
html += 'font-family:monospace;'
html += '}'
html += 'h1 {'
html += '}'
html += ''
html += 'p,h2,h3,.toc {'
html += '}'
html += ''
html += '.section {'
html += '}'
html += ''
html += '.content {'
html += 'max-width:72ch;'
html += 'white-space:normal;'
html += 'font-family:monospace;'
html += '}'
html += '@media (min-width:768px){'
html += '  .content {'
html += '    padding-left:8ch;'
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

titlelines.each { |l| html += "<b>#{l.gsub(/ /,'&nbsp')}</b><br>" }

html += '<div class="content">'

html += '<div class="toc"><ol>'
sections.each do |s| 
  html += "<li><a href=\"\##{s.object_id}\">"
  html += "#{s.title}</a></li>"
end
html += '</ol></div>'

sections.each { |s| html += s.emit }

html += '</div>'
html += ''
html += '</body>'
html += '</html>'

puts html
