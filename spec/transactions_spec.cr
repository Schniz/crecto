require "./spec_helper"
require "./helper_methods"

describe Crecto do
  describe "Repo" do
    describe "#transaction" do
      it "with an invalid changeset, should have errors" do
        user = User.new

        multi = Crecto::Multi.new
        multi.insert(user)

        multi = Crecto::Repo.transaction(multi)
        multi.errors.not_nil![0][:field].should eq("name")
        multi.errors.not_nil![0][:message].should eq("is required")
      end

      it "with a valid insert, should insert the record" do
        user = User.new
        user.name = "this should insert in the transaction"

        multi = Crecto::Multi.new
        multi.insert(user)

        multi = Crecto::Repo.transaction(multi)

        users = Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "this should insert in the transaction"))
        users.size.should be > 0
      end

      it "with a valid delete, should delete the record" do
        user = quick_create_user("this should delete")

        multi = Crecto::Multi.new
        multi.delete(user)
        Crecto::Repo.transaction(multi)

        users = Crecto::Repo.all(User, Crecto::Repo::Query.where(id: user.id))
        users.any?.should eq(false)
      end

      it "with a valid delete_all, should delete all records" do
        2.times do
          quick_create_user("test")
        end

        Crecto::Repo.delete_all(Post)

        multi = Crecto::Multi.new
        # `delete_all` needs to use `exec` on tranasaction, not `query`
        multi.delete_all(User)
        Crecto::Repo.transaction(multi)

        users = Crecto::Repo.all(User)
        users.size.should eq(0)
      end

      it "with a valid update, should update the record" do
        user = quick_create_user("this will change 89ffsf")

        user.name = "this should have changed 89ffsf"

        multi = Crecto::Multi.new
        multi.update(user)
        Crecto::Repo.transaction(multi)

        user = Crecto::Repo.get(User, user.id)
        user.name.should eq("this should have changed 89ffsf")
      end

      it "with a valid update_all, should update all records" do
        quick_create_user_with_things("testing_update_all", 123)
        quick_create_user_with_things("testing_update_all", 123)
        quick_create_user_with_things("testing_update_all", 123)

        multi = Crecto::Multi.new
        multi.update_all(User, Crecto::Repo::Query.where(name: "testing_update_all"), {things: 9494})
        Crecto::Repo.transaction(multi)

        Crecto::Repo.all(User, Crecto::Repo::Query.where(things: 123)).size.should eq 0
        Crecto::Repo.all(User, Crecto::Repo::Query.where(things: 9494)).size.should eq 3
      end

      it "should perform all transaction types" do
        Crecto::Repo.delete_all(Post)
        Crecto::Repo.delete_all(User)

        delete_user = quick_create_user("all_transactions_delete_user")
        update_user = quick_create_user("all_transactions_update_user")
        update_user.name = "all_transactions_update_user_ojjl2032"
        quick_create_post(quick_create_user("perform_all"))
        quick_create_post(quick_create_user("perform_all"))
        insert_user = User.new
        insert_user.name = "all_transactions_insert_user"

        multi = Crecto::Multi.new
        multi.insert(insert_user)
        multi.delete(delete_user)
        multi.delete_all(Post)
        multi.update(update_user)
        multi.update_all(User, Crecto::Repo::Query.where(name: "perform_all"), {name: "perform_all_io2oj999"})
        Crecto::Repo.transaction(multi)

        # check insert happened 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_insert_user")).size.should eq 1

        # check delete happened 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_delete_user")).size.should eq 0

        # check delete all happened 
        Crecto::Repo.all(Post).size.should eq 0

        # check update happened 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_update_user")).size.should eq 0
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_update_user_ojjl2032")).size.should eq 1

        # check update all happened 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "perform_all")).size.should eq 0
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "perform_all_io2oj999")).size.should eq 2
      end

      it "should rollback and not perform any of the transactions with an invalid query" do
        Crecto::Repo.delete_all(Post)
        Crecto::Repo.delete_all(User)

        delete_user = quick_create_user("all_transactions_delete_user")
        update_user = quick_create_user("all_transactions_update_user")
        update_user.name = "all_transactions_update_user_ojjl2032"
        quick_create_post(quick_create_user("perform_all"))
        quick_create_post(quick_create_user("perform_all"))
        insert_user = User.new
        insert_user.name = "all_transactions_insert_user"

        invalid_user = User.new

        multi = Crecto::Multi.new
        multi.insert(insert_user)
        multi.delete(delete_user)
        multi.delete_all(Post)
        multi.update(update_user)
        multi.update_all(User, Crecto::Repo::Query.where(name: "perform_all"), {name: "perform_all_io2oj999"})
        multi.insert(invalid_user)
        Crecto::Repo.transaction(multi)

        # check insert didn't happen 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_insert_user")).size.should eq 0

        # check delete didn't happen 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_delete_user")).size.should eq 1

        # check delete all didn't happen 
        Crecto::Repo.all(Post).size.should eq 2

        # check update didn't happen 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_update_user")).size.should eq 1
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "all_transactions_update_user_ojjl2032")).size.should eq 0

        # check update all didn't happen 
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "perform_all")).size.should eq 2
        Crecto::Repo.all(User, Crecto::Repo::Query.where(name: "perform_all_io2oj999")).size.should eq 0
      end
    end
  end
end
