should = require 'should'

Edgar = require 'index'


describe 'getting all form Ds for a company', () ->
  edgar = new Edgar
  boxCIK = '0001372612'

  it 'should get the correct number of forms', (done) ->
    edgar.getFormsByCIK boxCIK, (err, docs) ->
      docs.should.have.length 8
      total = 0
      for doc in docs
        doc.should.have.keys ['title', 'html', 'xml', 'summary', 'contents']
        doc.summary.should.have.keys ['date', 'amount']
        total += doc.summary.amount
      total.should.be.above 250000000  # $250 million
      done()
