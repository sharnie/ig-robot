require_relative '../instagram'

describe 'Instagram' do
  let(:instagram) {Instagram.new(access_token: ENV['ACCESS_TOKEN'])}

  context 'Robot mode' do
    it 'should instantiate' do
      expect(instagram).to be_an_instance_of(Instagram)
    end
  end

  context 'Return response from Instagram server' do
    it 'should find users by username then return user id' do
      users = instagram.user_search('instagram')
      expect(users.first['id']).to eq("25025320")
    end

    it 'should modify relationship between users' do
      user_id             = "25025320"
      relationship_status = instagram.get_relationship(user_id)['data']['outgoing_status']
      url = "https://api.instagram.com/v1/users/#{user_id}/relationship?access_token=#{ENV['ACCESS_TOKEN']}"

      new_relationship_status = relationship_status

      if relationship_status == 'none'
        response = JSON.parse(RestClient.post(url, access_token: ENV['ACCESS_TOKEN'], action: "follow"))
        new_relationship_status = response['data']['outgoing_status']
      elsif relationship_status == 'follows'
        response = JSON.parse(RestClient.post(url, access_token: ENV['ACCESS_TOKEN'], action: "unfollow"))
        new_relationship_status = response['data']['outgoing_status']
      end

      expect(relationship_status).to_not eq(new_relationship_status)
    end
  end
end