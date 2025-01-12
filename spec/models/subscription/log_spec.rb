require 'rails_helper'

RSpec.describe Subscription::Log, type: :model do
  it { should belong_to(:subscription) }
end
