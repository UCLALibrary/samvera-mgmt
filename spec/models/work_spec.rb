# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Work do
  subject(:work) { described_class.new }
  it_behaves_like 'a work with UCLA metadata'
end
