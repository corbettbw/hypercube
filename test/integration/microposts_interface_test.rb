require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:michael)
    @archer = users(:archer)
  end

  test "microposts interface" do
    # log in and get root path.
    log_in_as(@user)
    get root_path

    # Check pagination
    assert_select 'div.pagination'
    assert_select 'input[type=file]'

    # Make an invalid submission
    # Count the number of current microposts, submit invalid content, compare the count before and after.
    # Check for error explanation
    assert_no_difference 'Micropost.count' do
      post microposts_path, params:  { micropost: { content: "" } }
    end
    assert_select 'div#error_explanation'
    assert_select 'a[href=?]', '/?page=2' # correct pagination link

    # make valid submission
    # Check the number of microposts before and after
    content = "This micropost really ties the room together"
    image = fixture_file_upload('test/fixtures/kitten.jpg', 'image/jpeg')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content, image: image } }
    end
    assert assigns(:micropost).image.attached?
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body

    # delete a post
    # Click a delete link. I'm not sure how this gets around the confirmation button.
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end

    # visit a second user's page to make sure there are no 'delete' links
    get user_path(@archer)
    assert_select 'a', { text: 'delete', count: 0 }
  end

  test "micropost sidebar count" do
    log_in_as(@user)
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body
    # User with zero microposts
    other_user = users(:malory)
    log_in_as(other_user)
    get root_path
    assert_match "0 microposts", response.body
    other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match "1 micropost", response.body
  end
end
