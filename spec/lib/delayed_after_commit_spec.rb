require 'spec_helper'

RSpec.describe 'delayed after commit callback' do

  before :each do
    User.create!(name: 'Bob')
  end

  let(:bob) { User.where(name: 'Bob').first }

  describe "defering callback after update" do
    it 'should update the number of updates when sidekiq is running inline' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        bob.update_attributes(:name => 'Bob loblaw', :increment_enabled => true)
        expect(bob.reload.number_of_updates).to eq 1
      end
    end

    it 'should not update the number of updates increment_enabled is not true' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        bob.update_attributes(:name => 'Bob loblaw', :increment_enabled => false)
        expect(bob.reload.number_of_updates).to eq nil
      end
    end

    it 'should defer the "increment_number_of_updates" callback to the sidekiq queue' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          bob.update_attributes(:name => 'Bob loblaw', :increment_enabled => true)
        }.to change(Sidekiq::Queues['default'], :size).by(1)
        expect(Sidekiq::Queues['default'].first["args"].first).to include("increment_number_of_updates")
      end
    end
  end

  describe "defering callback after create" do
    it 'should update the number of updates when sidekiq is running inline' do
      Sidekiq::Testing.inline! do
        alice = User.create!(name: 'Alice')
        expect(alice.reload.number_of_letters_in_name).to eq 5
      end
    end

    it 'should defer the "calculate_number_of_letters_in_name" callback to the sidekiq queue' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          alice = User.create!(name: 'Alice')
        }.to change(Sidekiq::Queues['default'], :size).by(1)
        expect(Sidekiq::Queues['default'].last["args"].first).to include("calculate_number_of_letters_in_name")
      end
    end
  end
end
