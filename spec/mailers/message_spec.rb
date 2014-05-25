require "spec_helper"

describe Message do
  describe "welcome" do
    let(:mail) { Message.welcome }

    it "renders the headers" do
      mail.subject.should eq("Welcome")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end

    it "Send welcome message. `#welcome`", email_doc: true do
      mail.deliver
    end
  end

end
