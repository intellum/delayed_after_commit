# frozen_string_literal: true

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
        bob.update(name: 'Bob loblaw', increment_enabled: true)
        expect(bob.reload.number_of_updates).to eq 1
      end
    end

    it 'should not update the number of updates increment_enabled is not true' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        bob.update(name: 'Bob loblaw', increment_enabled: false)
        expect(bob.reload.number_of_updates).to eq nil
      end
    end

    it 'should defer the "increment_number_of_updates" callback to the sidekiq queue' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect do
          bob.update(name: 'Bob loblaw', increment_enabled: true)
        end.to change(Sidekiq::Queues['default'], :size).by(1)
        expect(Sidekiq::Queues['default'].first["args"]).to include("increment_number_of_updates")
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
        expect do
          User.create!(name: 'Alice')
        end.to change(Sidekiq::Queues['default'], :size).by(1)
        expect(Sidekiq::Queues['default'].last["args"]).to include("calculate_number_of_letters_in_name")
      end
    end
  end

  describe "a failing callback" do
    it 'should trigger the job with retry_max set when updating' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect do
          bob.fail_enabled = true
          bob.update(name: "Bob loblaw")
        end.to change(Sidekiq::Queues["default"], :size).by(1)

        job = Sidekiq::Queues["default"].last
        expect(job["retry"]).to be(false) # We are not using sidekiq's retry feature
        expect(job["args"]).to eq(["User", "failing_callback", bob.id.to_s, 3])
      end
    end

    it 'should raise an error if no max retries is set' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        expect do
          bob.fail_enabled = true
          bob.update(name: "Bob loblaw")
        end.to raise_error("This fails")
      end
    end

    it "should retry the correct amount of times" do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        expect do
          bob.update!(name: "0", fail_enabled: true)
        end.to raise_error("This fails")

        expect(bob.reload.number_of_updates.to_i).to eq(4)
      end
    end
  end
end
