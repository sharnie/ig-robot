require_relative 'instagram'
instagram = Instagram.new(access_token: ENV['ACCESS_TOKEN'])

puts <<-OPTION
##############################################################


->  Choose an option to follow users or like images
    # like
    # follow
    # exit


##############################################################
OPTION

def rinse
  minutes = 45
  loop do
    yield
    sleep minutes * 60
    File.delete(instagram.user_id_list) if File.exist?(instagram.user_id_list)
  end
end

loop do
  command = gets.strip
  case command
  when 'like'
    puts "Choose a hashtag to start liking:"
    tag     = gets.strip
    rinse do
      instagram.tag_image_id tag, 12
      instagram.like
    end

  when 'follow'
    puts <<-OPTION
    Choose one of the following to find users to follow:
      - Follow user followers (type followers)
      - Follow user following (type following)
      - Follow by hashtag (type hashtag)
    OPTION
    follow_command = gets.strip

    puts <<-INFO
      `Please ensure the user profile is public or you're following the user. Only apply to following and followers command.`
      What is the username or hashtag?
    INFO

    case follow_command
    when 'following'
      username = gets.strip
      rinse do
        instagram.follow_user_following(username)
      end
    when 'followers'
      username = gets.strip
      rinse do
        instagram.follow_user_followers(username)
      end
    when 'hashtag'
      tag   = gets.strip
      puts  "How many pages of results to like?"
      pages = gets.strip
      rinse do
        instagram.follow_user_by_tag(tag, pages)
      end
    end

  when 'exit'
    break
  else
    puts "Opps that's not an option!"
  end
end