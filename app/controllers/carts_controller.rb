class CartsController < ApplicationController
  before_filter :login_required, :except => [:notificate]
  before_filter :admin_required, :only => [:index]
  
  protect_from_forgery :except => [:notificate]

  def index
    @conditions = {}
    
    if !params[:status].blank?
      @conditions = { :status => Cart::STATUS[params[:status].intern] }
    end
    
    @carts = Cart.find(:all, :conditions => @conditions, :order => 'updated_at desc')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @carts }
    end
  end  
  
  # this is called for the user or admin
  # if not param[:id] sended return the current_cart
  # if params[:id] sended return the Cart but only if admin?
  def new
    @cart = current_cart            if params[:id].nil?
    @cart = Cart.find(params[:id])  if !params[:id].nil? && admin?
    record_not_found and return  if @cart.nil?
  end
  
  # this is colled for the user
  # update the current_cart
  # only add the Event pass through params[:event_ids]
  def confirm
    current_cart.carts_events.destroy_all
    
    if( params[:event_ids].nil? )
      flash[:error] = 'You should select at less one Event'
      redirect_to :action => 'new'
      return
    end
    
    current_cart.events = Event.find( params[:event_ids] )
    current_cart.invoice_info = params[:invoice_info]
    
    current_cart.save!
    
    @cart = current_cart
  end
  
  # this is the IPN paypal action call
  def notificate
    logger.info( "XXX: on notificate" )
    logger.info( "params: #{params.inspect}" )
  
    @cart = Cart.find( params[:invoice] )
    record_not_found and return  if @cart.nil?
    
    @cart.paypal_notificate( params )
  
    render :nothing => true
  end

  
  # this is the return_url from Paypal
  def complete
    logger.info( "params: #{params.inspect}" )
    
    @cart = current_user.carts.find( params[:invoice] )
    record_not_found and return  if @cart.nil?
    
    # if cart still ON_SESSION that is because there was not 
    # a paypal notification
    if @cart.status == Cart::STATUS[:ON_SESSION]
      @cart.update_attribute( :status, Cart::STATUS[:NOT_NOTIFIED] )
    end
    
    @cart.update_attribute( :paypal_complete_params, params )
    
    if @cart.status == Cart::STATUS[:COMPLETED]
      flash[:notice] = 'Payment was successfully.'
    else
      flash[:error] = 'Some error on payment!'
    end
  end
  
end
