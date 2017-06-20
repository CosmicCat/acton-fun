require "problem2"

RSpec.describe Problem2::Redactor do

  it "passes through records lacking redaction criteria" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"').to_s).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"')
  end

  it "redacts SSN" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="redact me regardless of contents", LastName="Flintstone"').to_s).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="XXX-REDACTED-XXX", LastName="Flintstone"')
  end

  it "redacts Credit Card Number" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="redact me regardless of contents", LastName="Flintstone"').to_s).to eq(
              '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", CC="XXX-REDACTED-XXX", LastName="Flintstone"')
  end

  it "redacts multiple fields in the same record" do
    r = Problem2::Redactor.new
    expect(r.redact(
             '2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", SSN="dontcare" CC="redact me regardless of contents", LastName="Flintstone"').to_s).to eq(
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

RSpec.describe Problem2::RedactionResult do

  it "Outputs other things you give it" do
    l = Problem2::RedactionResult.new
    l.message('message 1')
    l.message('message 2')
    expect(l.messages).to eq([
                               'message 1',
                               'message 2'
                             ])
  end

  it "looks like a string which contains the redacted log line" do
    l = Problem2::RedactionResult.new
    l.new_log_line = 'foobar'
    expect(l.to_s).to eq("foobar")
  end

end

RSpec.describe Problem2::FileHandler do
  TEST_PATH="test"
  OUTPUT_PATH="#{TEST_PATH}/redactions"

  it "handles the example input appropriately" do
    h = Problem2::FileHandler.new(TEST_PATH)
    h.redact_files
    redacted_contents = `zcat < #{OUTPUT_PATH}/test.log.gz`
    expect(redacted_contents).to eq(<<HERE)
2016-12-11 21:59:37 Account: 1783 Added record: 42153 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:03:07 Account: 1783 Updated Record: 22533 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:04:31 Account: 2557 Deleted record: 75854
2016-12-11 22:07:19 Account: 1783 Added record: 25744 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:15:01 Account: 2557 Updated Record: 28437 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:19:55 Account: 1783 Updated Record: 27665 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:23:25 Account: 3618 Deleted record: 78721
2016-12-11 22:27:37 Account: 1783 Added record: 44114 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:33:13 Account: 3618 Updated Record: 77807 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:35:19 Account: 3618 Updated Record: 23174 Fields: Content="Payment", Type="Mortgage", Industry="Finance", FirstName="Freod", LastName="Flintstone", SSN="XXX-REDACTED-XXX"
2016-12-11 22:43:01 Account: 1783 Deleted record: 59552
2016-12-11 22:47:55 Account: 2557 Deleted record: 86404
2016-12-11 22:55:37 Account: 1783 Updated Record: 18397 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-11 22:59:07 Account: 1783 Updated Record: 31495 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:07:31 Account: 2557 Updated Record: 61163 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:14:31 Account: 1783 Deleted record: 58138
2016-12-11 23:16:37 Account: 1783 Added record: 65332 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:25:01 Account: 1783 Added record: 58562 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:30:37 Account: 3618 Deleted record: 50866
2016-12-11 23:40:25 Account: 2557 Updated Record: 36261 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:45:19 Account: 1783 Updated Record: 61328 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-11 23:53:01 Account: 2557 Updated Record: 24753 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:02:07 Account: 1783 Added record: 46679 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:04:13 Account: 3618 Deleted record: 52633
2016-12-12 00:05:37 Account: 3618 Updated Record: 52571 Fields: Content="Payment", Type="Mortgage", Industry="Finance", FirstName="Fred", LastName="Flintstone", CC="XXX-REDACTED-XXX"
2016-12-12 00:15:25 Account: 2557 Added record: 49334 Fields: Content="Newsletter", Title="Froglegs Weekly", Industry="Food service", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:16:49 Account: 1783 Updated Record: 44668 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:25:13 Account: 2557 Updated Record: 18279 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:31:31 Account: 1783 Updated Record: 19162 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:40:37 Account: 2557 Added record: 10327 Fields: Content="Informational Pamphlet", Title="Eggs: Where to put them all?", Industry="Basket weaving", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:48:19 Account: 3618 Updated Record: 57685 Fields: Content="Bulletin", Title="Nonsense News", Industry="Technology", FirstName="Fred", LastName="Flintstone"
2016-12-12 00:54:37 Account: 2557 Deleted record: 27657
2016-12-12 01:03:01 Account: 2557 Deleted record: 41043
2016-12-12 01:09:19 Account: 3618 Added record: 86329 Fields: Content="Payment", Type="Mortgage", Industry="Finance", FirstName="Fred", LastName="Flintstone", SSN="XXX-REDACTED-XXX"
2016-12-12 01:16:19 Account: 3618 Updated Record: 85714 Fields: Content="Quote", Type="Auto", Industry="Insurance", FirstName="Fred", LastName="Flintstone", SSN="XXX-REDACTED-XXX"
HERE
  end

  it "has an audit log, giving information about each file touched" do
    h = Problem2::FileHandler.new(TEST_PATH)
    h.redact_files
    logfile_contents = File.read(h.logfile_path)
    expect(logfile_contents).to match('Processed test.log.gz - redacted 4/35 of total lines processed')
  end

  it "does not handle multiple runs - prompting users to blow away older output dir" do
    `mkdir #{OUTPUT_PATH}`
    h = Problem2::FileHandler.new(TEST_PATH)
    expect {h.redact_files}.to raise_error(RuntimeError)
  end

  after(:each) do
    `rm -rf #{OUTPUT_PATH}`
  end
end
