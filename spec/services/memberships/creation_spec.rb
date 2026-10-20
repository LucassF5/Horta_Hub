require "rails_helper"

RSpec.describe Memberships::Creation do
  let(:organization) { create(:organization) }

  it "uses member as the form param key" do
    expect(described_class.model_name.param_key).to eq("member")
  end

  it "builds the membership from the organization" do
    creation = described_class.new(organization: organization, role: "admin")

    expect(creation.membership).to be_new_record
    expect(creation.membership.organization_id).to eq(organization.id)
    expect(creation.membership.role).to eq("admin")
    expect(creation.membership).to be(creation.membership)
  end

  it "creates a user and membership with a generated password" do
    creation = described_class.new(
      organization: organization,
      username: "novo_membro",
      email_address: "novo@example.com",
      role: "manager"
    )

    expect { expect(creation.save).to be(true) }
      .to change(User, :count).by(1)
      .and change(Membership, :count).by(1)

    expect(creation.generated_password).to match(/\A[a-zA-Z0-9]{8}\z/)
    expect(User.last.authenticate(creation.generated_password)).to be_truthy
    expect(creation.existing_user?).to be(false)
    expect(creation.membership).to be_persisted
    expect(creation.membership.role).to eq("manager")
    expect(creation.membership.user).to eq(User.last)
  end

  it "reuses an existing account" do
    user = create(:user)
    create(:membership, user: user, organization: create(:organization))
    creation = described_class.new(
      organization: organization,
      username: "outro_nome",
      email_address: "  #{user.email_address.upcase} "
    )

    expect { expect(creation.save).to be(true) }
      .to change(User, :count).by(0)
      .and change(Membership, :count).by(1)

    expect(creation.existing_user?).to be(true)
    expect(creation.generated_password).to be_nil
    expect(creation.membership.user).to eq(user)
    expect(creation.membership.role).to eq("viewer")
    expect(user.reload.authenticate("password123")).to be_truthy
    expect(user.username).not_to eq("outro_nome")
  end

  it "rejects an account already in the organization" do
    user = create(:user)
    create(:membership, user: user, organization: organization)
    creation = described_class.new(organization: organization, email_address: user.email_address)

    expect { expect(creation.save).to be(false) }
      .to change(User, :count).by(0)
      .and change(Membership, :count).by(0)

    expect(creation.errors[:email_address]).to include("já pertence a esta organização")
  end

  it "rolls back the user when the membership is invalid" do
    creation = described_class.new(
      organization: organization,
      username: "novo_membro",
      email_address: "novo@example.com",
      role: "superuser"
    )

    expect { expect(creation.save).to be(false) }
      .to change(User, :count).by(0)
      .and change(Membership, :count).by(0)

    expect(creation.errors[:role]).to be_present
    expect(creation.generated_password).to be_nil
  end

  it "reports user validation errors" do
    creation = described_class.new(organization: organization, username: "ab", email_address: "novo@example.com")

    expect { expect(creation.save).to be(false) }.not_to change(User, :count)

    expect(creation.errors[:username]).to be_present
    expect(creation.generated_password).to be_nil
  end
end
