request = require('request').defaults jar: false
async   = require 'async'
xml2js  = require 'xml2js'
debug   = require 'debug'

debug = debug 'edgar'

SEC_URL   = "http://www.sec.gov"
EDGAR_URL = "#{SEC_URL}/cgi-bin/browse-edgar"

module.exports = class Edgar
  constructor: ->
    @parser = new xml2js.Parser()

  # given a url for a form, gets the link to the XML of the form
  getXMLLink: (url) =>
    parts = url.split '/'
    parts[parts.length - 1] = 'primary_doc.xml'
    parts.join '/'

  # given a url for a form, gets the link to the HTML of the form
  getHTMLLink: (url) =>
    parts = url.split '/'
    parts[parts.length - 1] = 'xslFormDX01/primary_doc.xml'
    parts.join '/'

  # given json data of form d (from xml parse),
  # get the relevant info/summary
  extractDocInfo: (json) =>
    offeringData = json.offeringData[0]
    amount = offeringData.offeringSalesAmounts[0].totalAmountSold[0]
    amount = parseInt(amount)
    date  : offeringData.typeOfFiling[0].dateOfFirstSale[0].value[0]
    amount: amount

  # given a doc object (with title, xml, html keys),
  # 1. puts the contents (as json from xml) into key 'content'
  # 2. puts a summary into key 'summary'
  getDocContent: (doc, callback) =>
    async.waterfall [
      (next) =>
        request.get doc.xml, next
      (res, xmlDoc, next) =>
        @parser.parseString xmlDoc, next
      (json, next) =>
        doc.contents = json.edgarSubmission
        doc.summary = @extractDocInfo doc.contents
        next null, doc
    ], callback


  # Gets all Form Ds for a given CIK
  #
  # ```
  # getFormsByCIK '0001372612', (err, docs) ->
  #   for doc in docs
  #     console.log 'Title:', doc.title
  #     console.log 'HTML Link:', doc.html
  #     console.log 'date:', doc.summary.date
  #     console.log 'amount:', doc.summary.amount
  #     console.log 'JSON doc:', doc.contents
  # ```
  getFormsByCIK: (cik, callback) =>
    query =
      action: 'getcompany'
      CIK: cik
      output: 'atom'
    async.waterfall [
      (next) =>
        request.get EDGAR_URL, qs: query, next
      (res, xmlData, next) =>
        @parser.parseString xmlData, next
      (json, next) =>
        feed = json.feed
        companyTitle = feed.title[0]
        debug 'Company:', companyTitle
        docs = []
        for entry in feed.entry
          type = entry.category[0].$.term
          title = entry.title[0]
          if /^D(\/A)?$/.test type        # Form D?
            link = entry.link[0].$.href
            docs.push
              title: title
              xml  : @getXMLLink(link)
              html : @getHTMLLink(link)
        next null, docs
      (docs, next) =>
        async.map docs, @getDocContent, next
    ], callback   # (err, docs)
