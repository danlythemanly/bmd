BMD: a simple markdown-like parser for a simple blog
====================================================

I decided to start a blog (15 years late is better than never?) and
decided that I wanted to write the HTML and CSS from scratch.  That
became tedious quickly, so I wrote this markdown-like parser for my
particular blog format.  The blog format is so simple that the
markdown-like version and the html version are pretty similar.  

### HTML features
- single column of left-justified monospace text
- 8 character padding at the left (unless the view port is too small,
  in which case there is no padding at the left)
- only 3 layers of headings: title, section, subsection
- tables of contents (1 for all sections, one per section containing
  subsections)

### BMD features
- markup-free headings, paragraphs, lists, italics
- no need to worry about padding
- no need to worry about tables of contents

### Running it

    ruby bmd.rb sample.bmd > sample.html

### Details

The blog title is expected to be in the .bmd file as figlet.  For
example:

        _      ____  _             
       / \    | __ )| | ___   __ _ 
      / _ \   |  _ \| |/ _ \ / _` |
     / ___ \  | |_) | | (_) | (_| |
    /_/   \_\ |____/|_|\___/ \__, |
                             |___/ 


Then there are sections headings, which are notated in the .bmd file
like this:

    ===== A Section =====

At the top of the blog, a table of contents will be generated
containing all sections.  The .bmd file doesn't have a table of
contents, though, and when writing blog entries, you don't need to
worry about them.  Sections may include subsections.  Subsection
headings are notated in the .bmd file like this:

    Subsection
    ----------

The generated HTML will similarly have a table of contents at the top
of each section listing subsections.  Again, the table of contents
doesn't show up in the .bmd file at all.  Sections and subsections can
both have paragraphs inside them:

    This is a paragraph.  For me, the lines are normally chopped in
    emacs because I like it that way.  Paragraphs have no indent or
    leading spaces regardless of if they're in sections or
    subsections.  

Paragraphs can contain italicized words, notated in the .bmd file as:

    Here comes an italicized *word*, isn't it cool?

Paragraphs can contain lists, or lists can stand alone.  Lists can be
bulleted or numbered, with the items separated by a blank newline or
not.  This is a list:

    1. item 1
    2. item 2

This is also a list:

    - item 1
    
    - item 2

And this is also a list:

    Here are some cool items:
    - item 1
    - item 2

In addition to paragraphs, sections and subsections can also have
images, specified like this:

    #img picture.jpg

All images are scaled to match the width of the text column.
Similarly, and just for fun, ascii art images can be generated from
.jpg files (at the appropriate text column width), specified like
this:

    #asciiimg picture.jpg

Everything except lists (including the title, section headings,
subsection headings, paragraphs, images, ascii images) must be
separated by a blank newline.  

### Bugs and Next Steps

The source .bmd file must end with a paragraph.  Ending with a list
breaks things.

There isn't any support for links yet.  I'm not sure how I haven't
needed them yet.

Written by: Dan Williams <danlythemanly@gmail.com> 7/26/2014

