# PDFArchive

This is a little tool to take a directory tree that contains PDF files
(and JPGs and PNGs), and do the following:

* generate thumbnails of the first page of each PDF, or of the image
  file for JPG/PNG
* extract the text from the PDF or image
* create an index page for each directory linking the source file to
  both its thumbnail and extracted text

## License

PDFArchive is released under the [MIT License](LICENSE).

## Built With

### PDFArchiver

PDFArchiver is written in [Python](https://python.org) and requires
version 3.9 or later.  It additionally relies on the following
libraries:

* [Jinja2](https://jinja.palletsprojects.com)

#### Indexer
* [JQuery](https://jquery.com)
* [Feather](https://feathericons.com)

#### Thumbnail generator
* [GraphicsMagick](https://graphicsmagick.org)

#### Text extractor
* [Poppler](https://poppler.freedesktop.org)
* [GraphicsMagick](https://graphicsmagick.org)
* [GOCR](https://jocr.sourceforge.net/)
* [Tesseract](https://github.com/tesseract-ocr/tesseract)
  
#### Text indexer
* [swish-e](https://github.com/swish-e/swish-e)

## Future Development

The first thing that needs doing is replacement of swish-e by a
currently supported search engine that builds cleanly on modern
systems.  From the root of the swish-e repository, you can run
`sed -i '' -e 's/uncompress2/uncompress42/g' $(grep -l uncompress
**/*.[ch])` before you run configure, and that will work (zlib got its
own `uncompress2` some time since swish-e was written).

The second thing is parallelization of some of the functionality, but
this will require careful attention to how to manage rate-limiting.  The
text extraction, in particular, is quite resource-intensive.


