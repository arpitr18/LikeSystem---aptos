module MyModule::LikeSystem {

    use std::signer;
    use aptos_std::table;

    struct Post has store, key {
        id: u64,
        likes: u64,
        likers: table::Table<address, bool>,
    }

    public fun create_post(owner: &signer, post_id: u64) {
        let likers_table = table::new<address, bool>();
        let post = Post {
            id: post_id,
            likes: 0,
            likers: likers_table,
        };
        move_to(owner, post);
    }

    public fun like_post(user: &signer, post_owner: address) acquires Post {
        let post = borrow_global_mut<Post>(post_owner);
        let user_addr = signer::address_of(user);

        if (table::contains(&post.likers, user_addr)) {
            return; // Already liked
        };

        table::add(&mut post.likers, user_addr, true);
        post.likes = post.likes + 1;
    }
}
