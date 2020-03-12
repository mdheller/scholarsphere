# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scholarsphere::Migration::Work, type: :model do
  subject(:migration_work) { described_class.new(work) }

  let(:work) { build(:public_work, :with_complete_metadata) }

  describe '#metadata' do
    context 'when the work has one title' do
      its(:metadata) { is_expected.to include(title: work.title.first) }
    end

    context 'when the work has multiple titles' do
      let(:work) { build(:work, title: ['title1', 'title2']) }

      it 'raises an error' do
        expect { migration_work.metadata }.to raise_error(Scholarsphere::Migration::Error)
      end
    end

    context 'when migrating creators' do
      it 'buils a nested hash with the appropriate metadata' do
        expect(migration_work.metadata[:creator_aliases_attributes].first[:alias]).to eq('creatorcreator')
      end
    end

    context 'with visibility' do
      its(:metadata) { is_expected.to include(visibility: 'open') }
    end

    context 'with an original identifier' do
      its(:metadata) { is_expected.to include(noid: work.id) }
    end

    context 'when the work is embargoed' do
      let(:embargo_date) { DateTime.now + 12.days }
      let(:work) { build(:work, :with_public_embargo, embargo_release_date: embargo_date) }

      its(:metadata) { is_expected.to include(embargoed_until: embargo_date.iso8601) }
    end

    context 'when the files are embargoed' do
      let(:embargo_date) { DateTime.now + 3.months }
      let(:fs1) { create(:file_set, embargo_release_date: (embargo_date - 1.month)) }
      let(:fs2) { create(:file_set, embargo_release_date: (embargo_date - 2.months)) }
      let(:fs3) { create(:file_set, embargo_release_date: embargo_date) }

      before do
        work.ordered_members << [fs1, fs3, fs2]
        work.thumbnail_id = fs1.id
      end

      its(:metadata) { is_expected.to include(embargoed_until: embargo_date.iso8601) }
    end
  end

  describe '#depositor' do
    its(:depositor) { is_expected.to eq(work.depositor) }
  end

  describe '#permissions' do
    its(:permissions) { is_expected.to include(edit_users: [work.depositor], read_groups: ['public']) }
  end

  describe '#files' do
    let(:user) { create(:user) }
    let(:work) { create(:public_work_with_pdf, :with_complete_metadata, depositor: user.login) }

    before { allow_any_instance_of(CreateDerivativesJob).to receive(:perform) }

    context 'when the files exist' do
      its(:files) { is_expected.to all(be_a(Pathname)) }
    end

    context 'when the files do not exist' do
      let(:mock_location) { instance_double('FileSetDiskLocation', path: 'this/is/bogus') }

      before { allow(FileSetDiskLocation).to receive(:new).and_return(mock_location) }

      it 'raises an error' do
        expect {
          migration_work.files
        }.to raise_error(Scholarsphere::Migration::Error, 'FileSet for bogus does not exist')
      end
    end
  end
end