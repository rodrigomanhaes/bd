es = Rails.application.config.elasticsearch_config
es_host = es['host'] || 'localhost'
es_port = es['port'] || '9200'

Tire.configure do
  logger "#{Rails.root}/log/elasticsearch.log"
  url "http://#{es_host}:#{es_port}"
end
