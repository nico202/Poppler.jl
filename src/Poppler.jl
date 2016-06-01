module Poppler

import Base.open ## Extends open

const libpoppler = "libpoppler-glib.so"

typealias FileURI ASCIIString

type PopplerDocument
    ptr::Ptr{Cint}
end

type PopplerPage
    ptr::Ptr{Cint}
end

## PopplerDocument — Information about a document 
open(uri::FileURI) = open(uri, "") ## WORKS
function open(uri::FileURI, password::ASCIIString) ## WORKS
    uri = ismatch(r"^file://", uri) ? uri : "file://$uri"
    document = ccall((:poppler_document_new_from_file, libpoppler),
                     PopplerDocument, ## FIXME: type document
                     (Cstring, Cint, Cint),
                     uri, 0, 0) ## FIXME: Error
    document.ptr == C_NULL ? error("Could not open file") : document
end

function pdfversion(document::PopplerDocument) ## WORKS
    version = bytestring(ccall((:poppler_document_get_pdf_version_string, libpoppler),
                               Ptr{UInt8},
                               (PopplerDocument,),
                               document))
end

function title(document) ## WORKS
    title = ccall((:poppler_document_get_title, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    title != C_NULL ? bytestring(title) : ""
end

function author(document) ## WORKS
    author = ccall((:poppler_document_get_author, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    author != C_NULL ? bytestring(author) : ""
end

function subject(document) ## WORKS
    subject = ccall((:poppler_document_get_subject, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    subject != C_NULL ? bytestring(subject) : ""
end

function keywords(document) ## DON'T KNOW IF WORKS
    keywords = ccall((:poppler_document_get_keywords, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    keywords != C_NULL ? bytestring(keywords) : ""
end

function creator(document) ## WORKS
    creator = ccall((:poppler_document_get_creator, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    creator != C_NULL ? bytestring(creator) : ""
end

function producer(document) ## WORKS
    producer = ccall((:poppler_document_get_producer, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    producer != C_NULL ? bytestring(producer) : ""
end

## WORKS
creationdate(document) = Dates.unix2datetime(Int(ccall((:poppler_document_get_creation_date, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)))

## WORKS
modificationdate(document) = Dates.unix2datetime(Int(ccall((:poppler_document_get_modification_date, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)))

function metadata(document) ## WORKS
    metadata = ccall((:poppler_document_get_metadata, libpoppler), Ptr{UInt8}, (PopplerDocument,), document)
    metadata != C_NULL ? bytestring(metadata) : ""
end

function islinearized(document) ## TO BE TESTED
    Bool(ccall((:poppler_document_is_linearized, libpoppler), Ptr{Bool}, (PopplerDocument,), document))
end

function hasattachments(document) ## TO BE TESTED
    Bool(ccall((:poppler_document_has_attachments, libpoppler), Ptr{Bool}, (PopplerDocument,), document))
end

## WORKS
pages(document) = Int(ccall((:poppler_document_get_n_pages, libpoppler), Ptr{Int64}, (PopplerDocument,), document))

"""
   page(document, index)

Returns a page object. Indexing in julia mode (starts from 1)
"""
function page(document::PopplerDocument, idx::Int) ## WORKS
    ccall((:poppler_document_get_page, libpoppler),
          PopplerPage,
          (PopplerDocument, Cint),
          document, idx - 1)
end

pagecontent(page::PopplerPage) = bytestring(ccall((:poppler_page_get_text, libpoppler), Ptr{UInt8}, (PopplerPage,), page))
pagecontent(document::PopplerDocument, pagen::Int) = pagecontent(page(document, pagen))

"""
   text(document)

Returns the text of all the pages of the document
"""
function text(document) ## FIXME: overload document object/text
    content = []
    for pagen in 1:pages(document)
        push!(content, pagecontent(document, pagen))
    end
    content
end

export open, pdfversion, title, author, subject, keywords, creator, producer, creationdate, modificationdate, metadata, islinearized, hasattachments, pages, page, pagecontent, text

end # module
