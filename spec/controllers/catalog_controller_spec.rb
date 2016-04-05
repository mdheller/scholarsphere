# frozen_string_literal: true
require 'spec_helper'

describe CatalogController, type: :controller do
  before(:all) do
    # TODO: Better testing strategy that doesn't require persisting objects
    # previous tests left artifacts so we need to remove them
    ActiveFedora::Cleaner.clean!
    create(:public_work, :with_pdf, title: ['Test Document PDF'])
    create(:public_work, title: ['Test 2 Document'], contributor: ['Contrib2'])
    create(:public_work, :with_complete_metadata)
  end

  before do
    allow_any_instance_of(GenericWork).to receive(:characterize_if_changed).and_yield
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  # Default depositor if none is supplied
  let(:user) { "user" }

  describe "#index" do
    describe "term search" do
      it "finds pdf files" do
        xhr :get, :index, q: "pdf"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("title"))[0]).to eql('Test Document PDF')
      end
      it "finds a file by title" do
        xhr :get, :index, q: "titletitle"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("title"))[0]).to eql('titletitle')
      end
      it "finds a file by tag" do
        xhr :get, :index, q: "tagtag"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("tag"))[0]).to eql('tagtag')
      end
      it "finds a file by subject" do
        xhr :get, :index, q: "subjectsubject"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("subject"))[0]).to eql('subjectsubject')
      end
      it "finds a file by creator" do
        xhr :get, :index, q: "creatorcreator"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("creator"))[0]).to eql('creatorcreator')
      end
      it "finds a file by contributor" do
        xhr :get, :index, q: "contributorcontributor"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("contributor"))[0]).to eql('contributorcontributor')
      end
      it "finds a file by publisher" do
        xhr :get, :index, q: "publisherpublisher"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("publisher"))[0]).to eql('publisherpublisher')
      end
      it "finds a file by based_near" do
        xhr :get, :index, q: "based_nearbased_near"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("based_near"))[0]).to eql('based_nearbased_near')
      end
      it "finds a file by language" do
        xhr :get, :index, q: "languagelanguage"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("language"))[0]).to eql('languagelanguage')
      end
      it "finds a file by resource_type" do
        xhr :get, :index, q: "resource_typeresource_type"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("resource_type"))[0]).to eql('resource_typeresource_type')
      end
      it "finds a file by format_label" do
        pending("Fields from characterization should be on the work")
        xhr :get, :index, q: "format_labelformat_label"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("file_format"))[0]).to eql('format_labelformat_label')
      end
      it "finds a file by description" do
        xhr :get, :index, q: "descriptiondescription"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
        expect(assigns(:document_list)[0].fetch(solr_field("description"))[0]).to eql('descriptiondescription')
      end
      it "finds a file by full_text" do
        pending("Full text only on the FileSet see sufia#1813")
        xhr :get, :index, q: "full_textfull_text"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
      end
      it "finds a file by depositor" do
        xhr :get, :index, q: user
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(3)
      end
      it "finds a file by depositor in advanced search" do
        xhr :get, :index, depositor: user, search_field: "advanced"
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(3)
      end
    end
    describe "facet search" do
      before do
        xhr :get, :index, q: "{f=#{contributor_facet}}Contrib2"
      end
      it "finds facet files" do
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
      end
    end
    describe "user with group search" do
      before do
        allow_any_instance_of(User).to receive(:groups).and_return(['umg/personal.testuser.testgroup'])
        xhr :get, :index, q: "{f=#{contributor_facet}}Contrib2"
      end
      it "finds facet files" do
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eql(1)
      end
    end
  end
end
