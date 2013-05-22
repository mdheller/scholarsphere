class TransfersController < ApplicationController
  load_and_authorize_resource :proxy_deposit_request, parent: false, except: :index
  before_filter :get_pid_and_authorize_depositor, only: [:new, :create]

  # Catch permission errors
  # TODO we should make this a module in Sufia
  rescue_from CanCan::AccessDenied do |exception|
    if current_user and current_user.persisted?
      redirect_to root_url, :alert => exception.message
    else
      session["user_return_to"] = request.url
      redirect_to new_user_session_url, :alert => exception.message
    end
  end

  def new
    @generic_file = GenericFile.load_instance_from_solr(@pid)
  end

  def create
    @proxy_deposit_request.sending_user = current_user
    if @proxy_deposit_request.save
      redirect_to transfers_path, notice: "Transfer request created"
    else
      redirect_to root_url, :alert => @proxy_deposit_request.errors.full_messages.to_sentence
    end
  end

  def index
    @incoming = ProxyDepositRequest.where(receiving_user_id: current_user.id)
    @outgoing = ProxyDepositRequest.where(sending_user_id: current_user.id)
  end

  def accept
    @proxy_deposit_request.transfer!
    redirect_to transfers_path, notice: "Transfer complete"
  end

  def reject
    @proxy_deposit_request.reject!
    redirect_to transfers_path, notice: "Transfer rejected"
  end

  def destroy
    @proxy_deposit_request.cancel!
    redirect_to transfers_path, notice: "Transfer canceled"
  end

  private

  def get_pid_and_authorize_depositor
    @pid = Sufia::Noid.namespaceize(params[:id])
    authorize! :edit, @pid
    raise Hydra::AccessDenied unless GenericFile.load_instance_from_solr(@pid).depositor == current_user.user_key
    @proxy_deposit_request.pid = @pid
  rescue
    redirect_to root_url, :alert => 'You are not authorized to transfer this file'
  end
end