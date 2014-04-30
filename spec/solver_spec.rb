require 'spec_helper'

describe Solver do

  subject { Solver.new }

  describe 'level1' do

    it 'should solve it' do
      question = 'Сребрит мороз увянувшее поле'
      subject.level_1(question).should == '19 октября'
    end

  end

  describe 'level 2' do

    it 'should solve it' do
      question = 'Сребрит мороз %WORD% поле'
      subject.level_2(question).should == 'увянувшее'
    end

  end

  describe 'level 3' do

    it 'should solve it' do
      question = "Сребрит мороз %WORD% поле,\nПроглянет день %WORD% будто поневоле"
      subject.level_3(question).should == 'увянувшее,как'
    end

  end

  describe 'level 4' do

    it 'should solve it' do
      question = "Сребрит мороз %WORD% поле,\nПроглянет день %WORD% будто поневоле\nИ скроется за край %WORD% гор."
      subject.level_4(question).should == 'увянувшее,как,окружных'
    end

  end


end
