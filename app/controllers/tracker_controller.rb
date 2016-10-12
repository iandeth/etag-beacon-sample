class TrackerController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    writer_page = "//client-test.s3.amazonaws.com/iandeth/20161012-etag/"
    ref = (request.headers['HTTP_REFERER'] || "")

    if ref.match(%r|^https?:#{writer_page}|)
      # 書き込み側からのリクエストだった場合は etag 発行 + stored data 作成
      data = 1
      etag = generate_etag()
      file = save_data(etag, data)
      render_response(etag, data, file.mtime.httpdate)
    else
      # 読み込み側ページからのリクエストの場合は stored data を読み取って返す
      etag = retrieve_etag_from_header()
      ret = load_data(etag)
      if ret.present?
        render_response(etag, ret[:data], ret[:last_modified])
      else
        data = 0
        etag = generate_etag()
        render_response(etag, data)
      end
    end
  end

  private
  # etag related
  def generate_etag
    SecureRandom.hex(14)
  end

  def retrieve_etag_from_header()
    (request.headers["HTTP_IF_NONE_MATCH"] || "").gsub(/"/, '')
  end

  def render_response(etag, data, last_modified=Time.zone.now.httpdate)
    expires_in 20.seconds, :public => true
    headers['ETag'] = %Q|"#{etag}"|
    headers['Last-Modified'] = last_modified
    render :js => %Q|var kz = { is_login_user: #{data} };|
  end

  # store data related
  def save_data(etag, data=0)
    raise "etag is blank" if etag.blank?
    f = _get_file_path(etag)
    FileUtils.mkpath(f.dirname) unless f.dirname.directory?
    File.open(f, 'w') {|fh| fh.write YAML.dump(data) }
    f
  end

  def load_data(etag)
    return if etag.blank?
    f = _get_file_path(etag)
    return unless f.exist?
    data = YAML.load_file(f)
    { data: data, last_modified: f.mtime.httpdate }
  end

  def _get_file_path(etag)
    head = etag[0,4]
    Rails.configuration.storage[:root_dir] + "#{head}/#{etag}.yml"
  end

  #def caching_allowed?
  #  false
  #end
end

