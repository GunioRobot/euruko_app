require File.dirname(__FILE__) + '/../test_helper'

class CartTest < ActiveSupport::TestCase
  def test_total_price
    @cart = carts(:cart_user1_event1_purchased)
    assert( @cart.total_price )
    assert_equal( events(:event1).price_cents, @cart.total_price )
    
    @cart.events << events(:event2)
    assert_equal( events(:event1).price_cents + events(:event2).price_cents, @cart.total_price )
  end
  
  def test_total_on_euros
    @cart = carts(:cart_user1_event1_purchased)
    assert( @cart.total_price_on_euros )
    assert_equal( events(:event1).price_euros, @cart.total_price_on_euros )
  end
  
  def test_one_cart_should_doesnot_have_the_same_event_twice
    @cart = carts(:cart_user1_event1_purchased)
    assert_raise(ActiveRecord::StatementInvalid) do
      @cart.events << events(:event1)
    end
  end
    
  def test_on_create_should_initialize_status
    @cart = users(:user1).carts.create!
    assert( @cart.valid? )
    assert_equal( Cart::STATUS[:ON_SESSION], @cart.status )
  end
  
  def test_paypal_url
    assert( carts(:cart_user1_event1_purchased).paypal_encrypted( 'return_url', 'notify_url' ) )
    # puts carts(:cart_user1_event1_purchased).paypal_url( 'return_url', 'notify_url' )
  end
  
  def test_is_purchased
    assert( carts(:cart_user1_event1_purchased).is_purchased? )
    assert( !carts(:cart_user1_event2_not_purchased).is_purchased? )
  end
  
  def test_name_scope_purchased
    assert( Cart.purchased.include?( carts(:cart_user1_event1_purchased) ) )
    assert( !Cart.purchased.include?( carts(:cart_user1_event2_not_purchased) ) )
  end
  
  def test_encrypt_for_paypal
    assert( Cart.encrypt_for_paypal( "texto" ) )
  end
  
  def test_paypal_notificate
    @cart = carts(:cart_user1_event1_purchased)
    assert( @cart.paypal_notificate( {:payment_status => Cart::STATUS[:COMPLETED]} ) )
    assert_equal( Cart::STATUS[:PAYPAL_ERROR], @cart.status )
  end
end