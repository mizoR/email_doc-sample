require 'spec_helper'
require 'forwardable'

module EmailDoc
  def self.doc_path
    Rails.root.join('doc', 'mail')
  end

  def self.documents
    @documents ||= Documents.new
  end

  def self.included(base)
    RSpec.configuration.after(:each, email_doc: true) do
      mail = ActionMailer::Base.deliveries.last
      EmailDoc.documents.append(self, mail)
    end

    RSpec.configuration.after(:suite) do
      EmailDoc.documents.write
    end
  end

  class Documents
    def initialize
      @table = Hash.new {|table, key| table[key] = [] }
    end

    def append(context, mail)
      document = EmailDoc::Document.new(context.clone, mail.clone)
      @table[document.pathname] << document
    end

    def write
      @table.each do |pathname, documents|
        pathname.parent.mkpath
        pathname.open("w") do |file|
          file << documents.map(&:render).join("\n")
        end
      end
    end
  end

  class Document
    extend Forwardable

    attr_reader :mail, :context

    def_delegators :mail, :subject, :from, :to, :reply_to, :body
    def_delegators :context, :described_class, :example
    def_delegators :example, :description

    def initialize(context, mail)
      @context = context
      @mail    = mail
    end

    def render
      ERB.new(<<-MD_END).result(binding)
# #{described_class}

## #{description}

```
    From: #{from}
 Subject: #{subject}
      To: #{to}
Reply to: #{reply_to}
```

```
#{body.encoded}
```
MD_END
    end

    def pathname
      @pathname ||= begin
        payload = @context.example.file_path.gsub(%r<\./spec/mailers/(.+)_spec\.rb>, '\1.md')
        EmailDoc.doc_path.join(payload)
      end
    end
  end
end
