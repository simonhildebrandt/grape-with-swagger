require "rack"
require "rack/cors"
require "grape"
require "grape-swagger"

$authors = [{ id: SecureRandom.uuid, name: 'Simon Hildebrandt' }]
$books = [{ id: SecureRandom.uuid, name: 'Websters Unite', author_id: $authors[0][:id] }]

class DummyAPI < Grape::API

  helpers do
    def books
      $books
    end
    def authors
      $authors
    end
  end

  [:author, :book].each do |singular|
    plural = "#{singular}s"

    helpers do
      define_method "#{singular}_by_id" do |id|
        send(plural).select {|r| r[:id] == id }[0]
      end
      define_method "delete_#{singular}" do |id|
        send(plural).reject! {|r| r[:id] == id }
      end
      define_method "create_#{singular}" do |**attrs|
        send(plural) << attrs
      end
    end
  end

  resource :authors do
    get do
      authors
    end

    params do
      requires :id, type: String, desc: "Author id"
    end
    get ':id' do
      author_by_id(params['id']) || error!(:not_found, 404)
    end

    params do
      requires :id, type: String
    end
    delete ':id' do
      delete_author(params['id'])
    end

    params do
      requires :name, type: String
    end
    post do
      create_author(id: SecureRandom.uuid, name: params['name'])
    end

    params do
      requires :id, type: String
      requires :name, type: String
    end
    put ':id' do
      authors[:name] = params['name']
    end
  end

  resource :books do
    get do
      books
    end

    params do
      requires :id, type: String
    end
    get ':id' do
      book_by_id(params['id']) || error!(:not_found, 404)
    end

    params do
      requires :id, type: String
    end
    delete ':id' do
      delete_book(params['id'])
      status 204
      ""
    end

    params do
      requires :name, type: String
      requires :author_id, type: String, values: -> () { $authors.map{|a| a[:id]} }, documentation: { values: nil }
    end
    post do
      create_book(id: SecureRandom.uuid, name: params['name'], author: params['author_id'] )
    end

    params do
      requires :name, type: String
    end
    put ':id' do
      books[:name] = params['name']
    end
  end
end

module API
  class Root < Grape::API
    format :json
    version 'v1', using: :header, vendor: 'simon'

    mount DummyAPI
    add_swagger_documentation info: { title: "Simon's API" }
  end
end



use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:put, :get, :post, :delete, :options]
  end
end

run API::Root

# http://petstore.swagger.io/?url=http://localhost:9292/swagger_doc
