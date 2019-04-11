require 'spec_helper'

describe "Dirty Singular Association" do
  describe 'has_one' do
    let(:story) { create :story }
    let(:image) { create :image, :title => "Superman", :url => "superman.jpg" }

    it 'sets secretary_previous' do
      story.image = image
      expect(story.secretary_previous_image).to eq nil
      story.save!
      expect(story.secretary_previous_image).to eq image
    end

    it 'marks the association as changed when the association is changed' do
      story.image = image
      expect(story.secretary_will_change_image).to eq true
    end

    it 'clears out the dirty association after commit' do
      story.image = image
      expect(story.secretary_will_change_image).to eq true
      story.save!
      expect(story.secretary_will_change_image).to eq nil
    end

    it "creates a new version when setting the association" do
      story.image = image
      story.save!

      expect(story.versions.count).to eq 2
      version = story.versions.last
      expect(version.object_changes["image"][0]).to eq Hash[]

      expect(version.object_changes["image"][1]).to eq Hash[{
        "title"       => "Superman",
        "url"         => "superman.jpg",
        "story_id"    => story.id
      }]
    end

    it 'makes a version when removing' do
      story.image = image
      story.save!
      expect(story.versions.count).to eq 2

      story.image = nil
      story.save!
      expect(story.versions.count).to eq 3

      versions = story.versions.order('version_number').to_a
      expect(versions.last.object_changes["image"][0]).to eq Hash[{
        "title"       => "Superman",
        "url"         => "superman.jpg",
        "story_id"    => story.id
      }]
      expect(versions.last.object_changes["image"][1]).to eq Hash[]
    end


    context 'with accepts_nested_attributes_for' do
      it 'adds a new version when adding association' do
        image_attributes = {
          "title" => "Superman",
          "url" => "super.jpg"
        }

        story.image_attributes = image_attributes
        story.save!
        expect(story.versions.count).to eq 2

        version = story.versions.order('version_number').last
        expect(version.object_changes["image"][0]).to eq Hash[]
        expect(version.object_changes["image"][1]).to eq Hash[{
          "title"       => "Superman",
          "url"         => "super.jpg",
          "story_id"    => story.id
        }]
      end

      it 'adds a new version when changing the existing associated object' do
        image_attributes = {
          "id" => image.id,
          "title" => "Lemon"
        }

        story.image = image
        story.save!
        expect(story.versions.count).to eq 2

        story.image_attributes = image_attributes
        story.save!
        expect(story.versions.count).to eq 3

        version = story.versions.order('version_number').last
        expect(version.object_changes["image"][0]).to eq Hash[{
          "title"       => "Superman",
          "url"         => "superman.jpg",
          "story_id"    => story.id
        }]
        expect(version.object_changes["image"][1]).to eq Hash[{
          "title" => "Lemon",
          "url" => "superman.jpg",
          "story_id" => story.id
        }]
      end

      it 'adds a new version when removing the association' do
        image_attributes = {
          "id" => image.id,
          "_destroy" => "1"
        }

        story.image = image
        story.save!
        expect(story.versions.count).to eq 2

        story.image_attributes = image_attributes
        story.save!
        expect(story.versions.count).to eq 3

        version = story.versions.order('version_number').last
        expect(version.object_changes["image"][0]).to eq Hash[{
          "title"       => "Superman",
          "url"         => "superman.jpg",
          "story_id"    => story.id
        }]
        expect(version.object_changes["image"][1]).to eq Hash[]
      end

      it 'does not add a new version if nothing has changed' do
        image_attributes = {
          "id" => image.id,
          "title" => "Superman"
        }

        story.image = image
        story.save!
        expect(story.versions.count).to eq 2

        story.image_attributes = image_attributes
        story.save!
        expect(story.versions.count).to eq 2
      end
    end

    describe '#secretary_will_change_association' do
      it 'is true if the association has changed' do
        expect(story.secretary_will_change_image).to eq nil
        story.image = image
        expect(story.secretary_will_change_image).to eq true
      end

      it 'is false after the parent object has been saved' do
        story.image = image
        expect(story.secretary_will_change_image).to eq true
        story.save!
        expect(story.secretary_will_change_image).to eq nil
      end

      it 'is false if the association has not changed' do
        pending "secretary_will_change_association is always considered changed when assigning"

        story.image = image
        expect(story.secretary_will_change_image).to eq true
        story.save!
        expect(story.secretary_will_change_image).to eq nil

        story.image = image
        expect(story.secretary_will_change_image).to eq nil
      end
    end
  end



  describe 'belongs_to' do
    let(:story) { create :story, :headline => "Headline", :body => "Body" }
    let(:image) { create :image, :title => "Superman", :url => "superman.jpg" }

    it 'sets secretary_previous' do
      image.story = story
      expect(image.secretary_previous_story).to eq nil
      image.save!
      expect(image.secretary_previous_story).to eq story
    end

    it 'marks the association as changed when the association is changed' do
      image.story = story
      expect(image.secretary_will_change_story).to eq true
    end

    it 'clears out the dirty association after commit' do
      image.story = story
      expect(image.secretary_will_change_story).to eq true
      image.save!
      expect(image.secretary_will_change_story).to eq nil
    end

    it "creates a new version when setting the association" do
      image.story = story
      image.save!

      expect(image.versions.count).to eq 2
      version = image.versions.order('version_number').last
      expect(version.object_changes["story"][0]).to eq Hash[]

      expect(version.object_changes["story"][1]).to eq Hash[{
        "headline" => "Headline",
        "body" => "Body"
      }]
    end

    it "tracks the foreign key as the normally" do
      image.story_id = story.id
      image.save!
      expect(image.versions.count).to eq 2

      version = image.versions.order('version_number').last
      expect(version.object_changes["story_id"][0]).to eq nil
      expect(version.object_changes["story_id"][1]).to eq story.id
      expect(version.description).to eq "Changed Story"
    end

    it 'makes a version when removing' do
      image.story = story
      image.save!
      expect(image.versions.count).to eq 2

      image.story = nil
      image.save!
      expect(image.versions.count).to eq 3

      versions = image.versions.order('version_number').to_a
      expect(versions.last.object_changes["story"][0]).to eq Hash[{
        "headline" => "Headline",
        "body" => "Body"
      }]
      expect(versions.last.object_changes["story"][1]).to eq Hash[]
    end

    describe '#secretary_will_change_association' do
      it 'is true if the association has changed' do
        expect(image.secretary_will_change_story).to eq nil
        image.story = story
        expect(image.secretary_will_change_story).to eq true
      end

      it 'is false after the parent object has been saved' do
        image.story = story
        expect(image.secretary_will_change_story).to eq true
        image.save!
        expect(image.secretary_will_change_story).to eq nil
      end

      it 'is false if the association has not changed' do
        pending "secretary_will_change_association is always considered changed when assigning"

        image.story = story
        expect(image.secretary_will_change_story).to eq true
        image.save!
        expect(image.secretary_will_change_story).to eq nil

        image.story = story
        expect(image.secretary_will_change_story).to eq nil
      end

      it 'is true when switching to or from nil' do
        # image.story is nil
        image.story = story
        expect(image.secretary_will_change_story).to eq true
        image.save!

        image.story = nil
        expect(image.secretary_will_change_story).to eq true
      end
    end
  end
end
