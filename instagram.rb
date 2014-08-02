require 'json'
require 'rest_client'
require 'dotenv'
Dotenv.load

class Instagram
  attr_reader :image_id_list, :user_id_list

  API = 'https://api.instagram.com/v1/'
  
  def initialize access_token: access_token
    @access_token  = access_token
    @image_ids     = []
    @user_ids      = []

    @image_id_list = "temp/image_id_list.txt"
    @user_id_list  = "temp/user_id_list.txt"
  end

  #################
  # Relationship Endpoints

  # Get the list of users this user follows.
  # https://api.instagram.com/v1/users/3/follows?access_token=ACCESS-TOKEN
  def user_follows user_id, pages: 1
    url = API + "users/#{user_id}/follows?access_token=" + @access_token
    pages.times do
      get(url)['data'].map do |user|
        @user_ids << user['id']
      end
      url = get(url)['pagination']['next_url']
    end
    export(@user_id_list, @user_ids)
  end

  # Get the list of users this user is followed by.
  # https://api.instagram.com/v1/users/3/followed-by?access_token=ACCESS-TOKEN
  def user_followers user_id, pages: 1
    url = API + "users/#{user_id}/followed-by?access_token=" + @access_token
    pages.times do
      get(url)['data'].map do |user|
        @user_ids << user['id']
      end
      url = get(url)['pagination']['next_url']
    end
    export(@user_id_list, @user_ids)
  end

  # Modify the relationship between the current user and the target user.
  # Action follow/unfollow/block/unblock/approve/deny.
  # https://api.instagram.com/v1/users/1574083/relationship?access_token=ACCESS-TOKEN
  def modify_relationship action
    File.open(@user_id_list, 'r') do |file|
      file.each do |user_id|
        url = API + "users/#{user_id.gsub(/(\n|,)$/, "")}/relationship?access_token=" + @access_token
        response = RestClient.post(url, access_token: @access_token, action: action)
        sleep(rand(3..6))

        puts response.code == 200 ? "Successfully #{action}: #{user_id}" : response
      end
    end
  end

  # Get information about a relationship to another user.
  # https://api.instagram.com/v1/users/1574083/relationship?access_token=ACCESS-TOKEN
  def get_relationship user_id
    url = API + "users/#{user_id}/relationship?access_token=" + @access_token
    get(url)
  end

  # Search for a user by name
  # https://api.instagram.com/v1/users/search?q=jack&access_token=ACCESS-TOKEN
  def user_search username
    url = API + "users/search?q=#{username}&access_token=" + @access_token
    get(url)['data']
  end

  def follow_user_followers username
    users = user_search(username)
    user_followers(users.first['id'])
    modify_relationship("follow")
  end

  def follow_user_following username
    users = user_search(username)
    user_follows(users.first['id'])
    modify_relationship("follow")
  end

  def follow_user_by_tag tag_name, pages
    tag_user_id(tag_name, pages: pages)
    modify_relationship("follow")
  end

  #################
  # Comment Endpoints

  # https://api.instagram.com/v1/media/555/comments?access_token=ACCESS-TOKEN
  # Create a comment on a media.
  # def post_comment media_id, message
  #   require 'nokogiri'
  #   require 'open-uri'

  #   media_endpoint = API + "media/#{media_id}?access_token=" + @access_token
  #   link = get(media_endpoint)['data']['link']

  #   p Nokogiri::HTML(open(link))
  # end


  #################
  # Like Endpoints

  # Yield each media id
  def media
    File.open(@image_id_list, 'r') do |file|
      file.each do |media_id|
        yield(media_id.gsub(",\n", ""))
        sleep(rand(5..14))
      end
      file.close
    end
  end

  # Get a list of users who have liked this media.
  # https://api.instagram.com/v1/media/555/likes?access_token=ACCESS-TOKEN
  def get_likes media_id
    url = API + "media/#{media_id}/likes?access_token=" + @access_token
    get(url)['data'].map {|data| data}
  end

  # Set likes on media by the currently authenticated user.
  # https://api.instagram.com/v1/media/{media-id}/likes
  def like
    media do |media_id|
      url = API + "media/#{media_id}/likes"
      post(url) do |response|
        case response.code
        when 200
          puts "Successfully liked media: #{media_id}"
        when 400
          puts response
        end
      end
    end
  end

  # Remove likes on media by the currently authenticated user.
  # https://api.instagram.com/v1/media/{media-id}/likes?access_token=ACCESS-TOKEN
  def unlike
    media do |media_id|
      url = API + "media/#{media_id}/likes/?access_token=" + @access_token
      delete(url) do |response|
        case response.code
        when 200
          print "Successfully unliked media: #{media_id}"
        when 400
          print response
        end
      end
    end
  end


  #################
  # Tags Endpoints

  # List of recent tag user id.
  def tag_user_id name, pages = 1
    url = API + "tags/#{name}/media/recent/?access_token=" + @access_token
    pages[:pages].to_i.times do
      get(url)['data'].map {|image| @user_ids << image['user']['id']}
      url = get(url)['pagination']['next_url']
    end
    export(@user_id_list, @user_ids)
  end

  # List of recent tag image id.
  def tag_image_id name, pages = 1
    url = API + "tags/#{name}/media/recent/?access_token=" + @access_token
    pages.times do
      get(url)['data'].map do |image|
        unless image['user_has_liked']
          @image_ids << image['id']
        end
      end
      url = get(url)['pagination']['next_url']
    end
    export(@image_id_list, @image_ids)
  end

  def export path, id_array
    File.open(path, "w+") do |file|
      id_array.map {|id| file << "#{id},\n" unless exist?(path, id)}
      file.close
    end
  end

  def exist? path, id
    File.open(path, "r").readlines.map { |e| e.gsub(/(,)$/, "").chomp }.include?(id)
  end

private
  
  def get url
    JSON.parse(RestClient.get(url))
  end

  def post url
    RestClient.post(url, access_token: @access_token){|response| yield(response)}
  end

  def delete url
    RestClient.delete(url, access_token: @access_token){|response| yield(response)}
  end
end