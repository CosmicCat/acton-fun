require "problem2"

RSpec.describe Problem2::Redactor do

  it "passes through records lacking redaction criteria" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"')).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"')
  end

  it "redacts SSN" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="redact me regardless of contents", LastName="Flintstone"')).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="XXX-REDACTED-XXX", LastName="Flintstone"')
  end

  it "redacts Credit Card Number" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="redact me regardless of contents", LastName="Flintstone"')).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="XXX-REDACTED-XXX", LastName="Flintstone"')
  end

  it "redacts multiple fields in the same record" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="dontcare" CC="redact me regardless of contents", LastName="Flintstone"')).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="XXX-REDACTED-XXX" CC="XXX-REDACTED-XXX", LastName="Flintstone"')
  end

  it "should redact when SSN or CC are present" do
    r = Problem2::Redactor.new
    expect(r.should_redact?(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="redact me regardless of contents", LastName="Flintstone"')).to be true
  end

end

RSpec.describe Problem2::UpdateCreateTokenizer do

  it "locates all fields in record" do
    log_line = '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="redact me regardless of contents", LastName="Flintstone"'
    uct = Problem2::UpdateCreateTokenizer.new(log_line)
    expect(uct.fields.sort).to eq([
                                    "CC",
                                    "Content",
                                    "Industry",
                                    "LastName",
                                    "Title",
                                  ])
  end

  it "allows us to edit records" do
    log_line = '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="redact me regardless of contents", LastName="Flintstone"'
    uct = Problem2::UpdateCreateTokenizer.new(log_line)
    uct.rewrite_field("CC", "Something different")
    expect(uct.log_line).to eq('2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="Something different", LastName="Flintstone"')
  end

end
