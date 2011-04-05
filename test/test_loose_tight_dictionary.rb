require 'helper'

require 'remote_table'

$verbose = false
# $tee = $stdout

class TestLooseTightDictionary < Test::Unit::TestCase
  def setup
    clear_ltd
    
    # dh 8 400
    @a_left = ['DE HAVILLAND CANADA DHC8400 Dash 8']
    @a_right = ['DEHAVILLAND DEHAVILLAND DHC8-400 DASH-8']
    # dh 88
    @b_left = ['ABCDEFG DH88 HIJKLMNOP']
    # dh 89
    @c_right = ['ABCDEFG DH89 HIJKLMNOP']
    # dh 8 200
    @d_left = ['DE HAVILLAND CANADA DHC8200 Dash 8']
    @d_right = ['BOMBARDIER DEHAVILLAND DHC8-200Q DASH-8']
    @d_lookalike = ['ABCD DHC8200 Dash 8']
    
    @t_1 = [ '/(dh)c?-?(\d{0,2})-?(\d{0,4})(?:.*?)(dash|\z)/i', 'good tightening for de havilland' ]
    
    @r_1 = [ '/(dh)c?-?(\d{0,2})-?(\d{0,4})(?:.*?)(dash|\z)/i', 'good identity for de havilland' ]
    
    @left = [
      @a_left,
      @b_left,
      ['DE HAVILLAND DH89 Dragon Rapide'],
      ['DE HAVILLAND CANADA DHC8100 Dash 8 (E9, CT142, CC142)'],
      @d_left,
      ['DE HAVILLAND CANADA DHC8300 Dash 8'],
      ['DE HAVILLAND DH90 Dragonfly']
    ]
    @right = [
      @a_right,
      @c_right,
      @d_right,
      ['DEHAVILLAND DEHAVILLAND DHC8-100 DASH-8'],
      ['DEHAVILLAND DEHAVILLAND TWIN OTTER DHC-6']
    ]
    @tightenings = []
    @identities = []
    @blockings = []
    @positives = []
    @negatives = []
  end

  def clear_ltd
    @_ltd = nil
  end
  
  def ltd
    @_ltd ||= LooseTightDictionary.new  @right,
                                        :tightenings => @tightenings,
                                        :identities => @identities,
                                        :blockings => @blockings,
                                        :positives => @positives,
                                        :negatives => @negatives,
                                        :blocking_only => @blocking_only,
                                        :verbose => $verbose,
                                        :tee => $tee
  end

  should "optionally only pay attention to things that match blockings" do
    assert_equal @a_right, ltd.left_to_right(@a_left)

    clear_ltd
    @blocking_only = true
    assert_equal nil, ltd.left_to_right(@a_left)

    clear_ltd
    @blocking_only = true
    @blockings.push ['/dash/i']
    assert_equal @a_right, ltd.left_to_right(@a_left)
  end
  
  # the example from the readme, considerably uglier here
  should "check a simple table" do
    @right = [ 'seamus', 'andy', 'ben' ]
    @positives = [ [ 'seamus', 'Mr. Seamus Abshere' ] ]
    left = [ 'Mr. Seamus Abshere', 'Sr. Andy Rossmeissl', 'Master BenT' ]
  
    assert_nothing_raised do
      ltd.check left
    end
  end
  
  should "treat a String as a full record if passed through" do
    dash = 'DHC8-400'
    b747 = 'B747200/300'
    dc9 = 'DC-9-10'
    right_records = [ dash, b747, dc9 ]
    simple_ltd = LooseTightDictionary.new right_records, :verbose => $verbose, :tee => $tee
    assert_equal dash, simple_ltd.left_to_right('DeHavilland Dash-8 DHC-400')
    assert_equal b747, simple_ltd.left_to_right('Boeing 747-300')
    assert_equal dc9, simple_ltd.find('McDonnell Douglas MD81/DC-9')
  end
  
  should "call it a mismatch if you hit a blank positive" do
    @positives.push [@a_left[0], '']
    assert_raises(LooseTightDictionary::Mismatch) do
      ltd.left_to_right @a_left
    end
  end

  should "call it a false positive if you hit a blank negative" do
    @negatives.push [@a_left[0], '']
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.left_to_right @a_left
    end
  end
  
  should "have a false match without blocking" do
    # @d_left will be our victim
    @right.push @d_lookalike
    @tightenings.push @t_1
    
    assert_equal @d_lookalike, ltd.left_to_right(@d_left)
  end
  
  should "do blocking if the left matches a block" do
    # @d_left will be our victim
    @right.push @d_lookalike
    @tightenings.push @t_1
    @blockings.push ['/(bombardier|de ?havilland)/i']
    
    assert_equal @d_right, ltd.left_to_right(@d_left)
  end
  
  should "treat blocks as exclusive" do
    @right = [ @d_left ]
    @tightenings.push @t_1
    @blockings.push ['/(bombardier|de ?havilland)/i']

    assert_equal nil, ltd.left_to_right(@d_lookalike)
  end
  
  should "only use identities if they stem from the same regexp" do
    @identities.push @r_1
    @identities.push [ '/(cessna)(?:.*?)(citation)/i' ]
    @identities.push [ '/(cessna)(?:.*?)(\d\d\d)/i' ]
    x_left = [ 'CESSNA D-333 CITATION V']
    x_right = [ 'CESSNA D-333' ]
    @right.push x_right
    
    assert_equal x_right, ltd.left_to_right(x_left)
  end
  
  should "use the best score from all of the tightenings" do
    x_left = ["BOEING 737100"]
    x_right = ["BOEING BOEING 737-100/200"]
    x_right_wrong = ["BOEING BOEING 737-900"]
    @right.push x_right
    @right.push x_right_wrong
    @tightenings.push ['/(7\d)(7|0)-?\d{1,3}\/(\d\d\d)/i']
    @tightenings.push ['/(7\d)(7|0)-?(\d{1,3}|[A-Z]{0,3})/i']
    
    assert_equal x_right, ltd.left_to_right(x_left)
  end
  
  should "compare using prefixes if tightened key is shorter than correct match" do
    x_left = ["BOEING 720"]
    x_right = ["BOEING BOEING 720-000"]
    x_right_wrong = ["BOEING BOEING 717-200"]
    @right.push x_right
    @right.push x_right_wrong
    @tightenings.push @t_1
    @tightenings.push ['/(7\d)(7|0)-?\d{1,3}\/(\d\d\d)/i']
    @tightenings.push ['/(7\d)(7|0)-?(\d{1,3}|[A-Z]{0,3})/i']
    
    assert_equal x_right, ltd.left_to_right(x_left)
  end
  
  should "use the shortest original input" do
    x_left = ['De Havilland DHC8-777 Dash-8 Superstar']
    x_right = ['DEHAVILLAND DEHAVILLAND DHC8-777 DASH-8 Superstar']
    x_right_long = ['DEHAVILLAND DEHAVILLAND DHC8-777 DASH-8 Superstar/Supernova']
    
    @right.push x_right_long
    @right.push x_right
    @tightenings.push @t_1
    
    assert_equal x_right, ltd.left_to_right(x_left)
  end
  
  should "perform lookups left to right" do
    assert_equal @a_right, ltd.left_to_right(@a_left)
  end

  should "succeed if there are no checks" do
    assert_nothing_raised do
      ltd.check @left
    end
  end

  should "succeed if the positive checks just work" do
    @positives.push [ @a_left[0], @a_right[0] ]
  
    assert_nothing_raised do
      ltd.check @left
    end
  end

  should "fail if positive checks don't work" do
    @positives.push [ @d_left[0], @d_right[0] ]

    assert_raises(LooseTightDictionary::Mismatch) do
      ltd.check @left
    end
  end

  should "succeed if proper tightening is applied" do
    @positives.push [ @d_left[0], @d_right[0] ]
    @tightenings.push @t_1

    assert_nothing_raised do
      ltd.check @left
    end
  end

  should "use a Google Docs spreadsheet as a source of tightenings" do
    @positives.push [ @d_left[0], @d_right[0] ]
    @tightenings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=0&output=csv', :headers => false
  
    # sabshere 9/30/10 this shouldn't raise anything
    # but the tightenings have been changed... we should be using test-only tightenings, not production ones
    # assert_nothing_raised do
    assert_raises(LooseTightDictionary::Mismatch) do
      ltd.check @left
    end
  end
  
  should "fail if negative checks don't work" do
    @negatives.push [ @b_left[0], @c_right[0] ]
  
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.check @left
    end
  end
  
  should "do inline checking" do
    @negatives.push [ @b_left[0], @c_right[0] ]
  
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.left_to_right @b_left
    end
  end

  should "fail if negative checks don't work, even with tightening" do
    @negatives.push [ @b_left[0], @c_right[0] ]
    @tightenings.push @t_1
  
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.check @left
    end
  end

  should "succeed if proper identity is applied" do
    @negatives.push [ @b_left[0], @c_right[0] ]
    @positives.push [ @d_left[0], @d_right[0] ]
    @identities.push @r_1
  
    assert_nothing_raised do
      ltd.check @left
    end
  end
end
