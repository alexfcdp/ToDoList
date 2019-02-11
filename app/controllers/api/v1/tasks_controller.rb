# frozen_string_literal: true

class Api::V1::TasksController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource :project, only: %i[index create]
  load_and_authorize_resource :task, through: :project, only: %i[index create]
  load_and_authorize_resource except: %i[index create]

  resource_description do
    formats ['json']
    error 401, 'Unauthorized'
    error 422, 'Validation Error'
    error 500, 'Internal Server Error'
  end

  def_param_group :task do
    param :data, Hash, required: true do
      param :attributes, Hash, required: true do
        param :name, String, required: true
        param :deadline, String
        param :position, :number
      end
    end
  end

  def_param_group :complete do
    param :id, :number, required: true
    param :data, Hash, required: true do
      param :attributes, Hash, required: true do
        param :done, :boolean, required: true
      end
    end
  end

  def_param_group :position do
    param :id, :number, required: true
    param :data, Hash, required: true do
      param :attributes, Hash, required: true do
        param :position, :number, required: true
      end
    end
  end

  api :GET, '/v1/projects/:project_id/tasks', 'A list of Tasks'
  param :project_id, :number, required: true
  def index
    render json: @tasks
  end

  api :GET, '/v1/tasks/:id', 'Shows the Task'
  param :id, :number, required: true
  def show
    render json: @task
  end

  api :POST, '/v1/projects/:project_id/tasks', 'Creates a Task'
  param :project_id, :number, required: true
  param_group :task
  def create
    @task = Task.new(task_params)
    if @task.save
      render json: @task, status: :created
    else
      render json: { error: @task.errors }, status: :unprocessable_entity
    end
  end

  api :PATCH, '/v1/tasks/:id', 'Updates the Task'
  param_group :task
  def update
    if @task.update(task_params)
      render json: @task, status: :ok
    else
      render json: { error: @task.errors }, status: :unprocessable_entity
    end
  end

  api :DELETE, '/v1/tasks/:id', 'Deletes the Task'
  param :id, :number, required: true
  def destroy
    @task.destroy
    head :no_content
  end

  api :PATCH, '/v1/tasks/:id/complete', 'Mark Task as completed'
  param_group :complete
  def complete
    if @task.update(task_complete_params)
      render json: @task, status: :ok
    else
      render json: { error: @task.errors }, status: :unprocessable_entity
    end
  end

  api :PATCH, '/v1/tasks/:id/position', 'Change Position of Task'
  param_group :position
  def position
    if @task.insert_at(task_position_params)
      render json: @task, status: :ok
    else
      render json: { error: @task.errors }, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.require(:data).require(:attributes).permit(:name, :position, :deadline).tap do |whitelisted|
      whitelisted[:project_id] = params[:project_id] if params[:project_id]
      whitelisted[:id] = params[:id] if params[:id]
    end
  end

  def task_complete_params
    params.require(:data).require(:attributes).permit(:done)
  end

  def task_position_params
    params.require(:data).require(:attributes).permit(:position)[:position].to_i
  end
end
