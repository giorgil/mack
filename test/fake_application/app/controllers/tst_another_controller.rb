class TstAnotherController < Mack::Controller::Base
  
  def foo
    "tst_another_controller: foo: id: '#{params(:id)}' pickles: '#{params(:pickles)}'"
  end
  
  def bar
    %{
      <form action="<%= pickles_url %>" method="post">
        <input type="text" name="id"/ ><br>
        <textarea name="pickles"></textarea><br>
        <input type="submit" name="submit">
      </form>
    }
  end
  
  def act_level_layout_test_action
    render(:text => "I've changed the layout in the action!", :layout => :my_super_cool)
  end
  
  def layout_set_to_nil_in_action
    render(:text => "I've set my layout to nil!", :layout => nil)
  end
  
  def layout_set_to_false_in_action
    render(:text => "I've set my layout to false!", :layout => false)
  end
  
  def layout_set_to_unknown_in_action
    render(:text => "I've set my layout to some layout that don't exist!", :layout => :i_dont_exist)
  end
  
  def env
    "MACK_ENV: #{MACK_ENV}"
  end
  
  def kill_kenny_bad
    kill_kenny
  end
  
  def say_love_you
    love_you
  end
  
  def regardless_of_string_or_symbol
    x = ""
    x << "from_string: foo=#{params("foo")}\n"
    x << "from_symbol: foo=#{params(:foo)}\n"
    x
  end
  
  def params_return_as_hash
    @foo = params(:foo)
    x = ""
    x << "class: #{params(:foo).class}]\n"
    x << "inspect: #{params(:foo).inspect}"
    x
  end
  
end