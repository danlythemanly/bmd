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
- publication links

### BMD features
- markup-free headings, paragraphs, lists, italics
- no need to worry about padding
- no need to worry about tables of contents
- no need to worry about fixing up publication indexes

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


At the top of the blog, a table of contents will be generated
containing all sections.  The .bmd file doesn't have a table of
contents, though, and when writing blog entries, you don't need to
worry about them.  Sections headings are notated in the .bmd file like
this:

    ===== A Section =====

Sections may include subsections.  The generated HTML will similarly
have a table of contents at the top of each section listing these
subsections.  Again, the table of contents doesn't show up in the .bmd
file at all.  If the table of contents for a section is not desired,
the section heading can be notated like this:

    ===== A Section =====|

Subsection headings are notated in the .bmd file like this:

    Subsection
    ----------

Sections and subsections can both have paragraphs inside them:

    This is a paragraph.  For me, the lines are normally chopped in
    emacs because I like it that way.  Paragraphs have no indent or
    leading spaces regardless of if they're in sections or
    subsections.  

Paragraphs can contain italicized words, notated in the .bmd file as:

    Here comes an italicized *word*, isn't it cool?

Paragraphs can also contain links in reference-at-the-bottom mode,
which look like this:

    Here is a [link][x] in a sentence.

Then later:

    [x]: http://www.google.com

There is also a special type of link, which is a link to a publication
bibliography entry.  A publication bibliography entry is specified
like this:

    [[foo]]: http://url.of.publication.pdf
      Bibliography Entry with authors, [title], venue year, etc.

This entry will appear at the end of the HTML, in an ordered list.
The part of the entry in single brackets (e.g., title in this case)
will link to the appropriate URL.  Elsewhere in the paragraph, links
to the entry look like this:

    I wrote a paper[[foo]] that is really great!

These references will be replaced with a hyperlink to the bibliography
entry (via an anchor) and the correct index into the ordered list
between single brackets.

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

The source .bmd file must end with a paragraph or a link reference.
Ending with a list breaks things.

Written by: Dan Williams <danlythemanly@gmail.com> 7/26/2014

