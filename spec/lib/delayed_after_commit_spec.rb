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
        bob.update(:name => 'Bob loblaw', :increment_enabled => true)
        expect(bob.reload.number_of_updates).to eq 1
      end
    end

    it 'should not update the number of updates increment_enabled is not true' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.inline! do
        bob.update(:name => 'Bob loblaw', :increment_enabled => false)
        expect(bob.reload.number_of_updates).to eq nil
      end
    end

    it 'should defer the "increment_number_of_updates" callback to the sidekiq queue' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          bob.update(:name => 'Bob loblaw', :increment_enabled => true)
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

  describe "a failing callback" do
    it 'should trigger the job with retry_max set when updating' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          bob.fail_enabled = true
          bob.update(:name => 'Bob loblaw')
        }.to change(Sidekiq::Queues['default'], :size).by(1)

        job = Sidekiq::Queues['default'].last
        args = YAML.load(job["args"].first).last

        expect(job["retry"]).to be(false)

        expect(args[0]).to equal(:failing_callback)
        expect(args[1]).to equal(bob.id)
        expect(args[2]).to equal(3)
        expect(args[3]).to be(nil)
      end
    end

    it 'should raise an error if no max retries is set' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          User.enqueue_delayed_method(:failing_callback, bob.id)
        }.to raise_error("This fails")
      end
    end

    it 'should trigger a retry after failing once if a max number of retries is set' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          User.enqueue_delayed_method(:failing_callback, bob.id, 3)
        }.to raise_error("This fails")

        job = Sidekiq::Queues['default'].last
        args = YAML.load(job["args"].first).last

        expect(job["retry"]).to be(false)

        expect(args[0]).to equal(:failing_callback)
        expect(args[1]).to equal(bob.id)
        expect(args[2]).to equal(3)
        expect(args[3]).to equal(1)
      end
    end

    it 'should trigger a retry after failing twice if a max number of retries is set' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          User.enqueue_delayed_method(:failing_callback, bob.id, 3, 2)
        }.to raise_error("This fails")

        job = Sidekiq::Queues['default'].last
        args = YAML.load(job["args"].first).last

        expect(job["retry"]).to be(false)

        expect(args[0]).to equal(:failing_callback)
        expect(args[1]).to equal(bob.id)
        expect(args[2]).to equal(3)
        expect(args[3]).to equal(3)
      end
    end


    it 'should not trigger a retry after reaching the maximum number' do
      Sidekiq::Worker.clear_all
      Sidekiq::Testing.fake! do
        expect {
          User.enqueue_delayed_method(:failing_callback, bob.id, 3, 3)
        }.to raise_error("This fails")

        job = Sidekiq::Queues['default'].last
        expect(job).to be(nil)
      end
    end
  end
end
