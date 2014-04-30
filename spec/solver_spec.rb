require 'spec_helper'

describe Solver do

  before(:all) { @subject = Solver.new }

  describe 'level1' do

    it 'should solve it' do
      question = 'Сребрит мороз увянувшее поле'
      @subject.level_1(question).should == '19 октября'
    end

  end

  describe 'level 2' do

    it 'should solve it' do
      question = 'Сребрит мороз %WORD% поле'
      @subject.level_2(question).should == 'увянувшее'
    end

    it 'should solve it' do
      question  = 'Быть %WORD% — хорошо, спокойным — лучше вдвое'
      @subject.level_2(question).should == 'славным'
    end

    it 'should solve it' do
      question  = 'Ты приближаешься к %WORD% поре'
      @subject.level_2(question).should == 'сомнительной'
    end

    it 'should solve it' do
      question  = "     Живые %WORD%"
      @subject.level_2(question).should == 'впечатленья'
    end

  end

  describe 'level 3' do

    it 'should solve it' do
      question = "Сребрит мороз %WORD% поле,\nПроглянет день %WORD% будто поневоле"
      @subject.level_3(question).should == 'увянувшее,как'
    end

  end

  describe 'level 4' do

    it 'should solve it' do
      question = "Сребрит мороз %WORD% поле,\nПроглянет день %WORD% будто поневоле\nИ скроется за край %WORD% гор."
      @subject.level_4(question).should == 'увянувшее,как,окружных'
    end

  end

  describe 'level 5' do

    it 'should solve it' do
      question = "В споров сияньи исчезает"
      @subject.level_5(question).should == 'ее,споров'
    end

    it 'should solve it' do
      question = "Вздыхал сижу царствии небес"
      @subject.level_5(question).should == 'о,сижу'
    end

  end


end
