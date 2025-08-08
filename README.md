# ❤️ LikeSystem: A Simple Social Interaction Module on Aptos

Welcome to **LikeSystem**, a foundational Move module for the Aptos blockchain that demonstrates a basic on-chain liking mechanism. This module allows users to create "posts" (represented as on-chain resources) and for other users to "like" them, ensuring that each user can only like a post once.

It's a perfect starting point for developers looking to understand resource management, tables, and signer interactions in Move.

-----

## ✨ Features

  * **Post Creation**: Any user can create a post, which is stored directly under their account as a resource.
  * **Like Functionality**: Users can like any post on the network.
  * **Idempotent Likes**: The system elegantly handles duplicate likes. If a user tries to like a post they've already liked, the state remains unchanged, preventing errors and wasted gas on state changes.
  * **On-Chain Tracking**: All likes are tracked transparently in a `Table` within the post resource, providing a verifiable record of interactions.

-----

## 🚀 Core Concepts

This module is built around a central data structure, the `Post` resource.

### The `Post` Resource

The `Post` is a `struct` that holds all the information about a single post. It has the `store` and `key` abilities, meaning it can be stored as a top-level resource under an account's address.

```move
struct Post has store, key {
    id: u64,
    likes: u64,
    likers: table::Table<address, bool>,
}
```

  * `id: u64`: A unique identifier for the post.
  * `likes: u64`: A simple counter for the total number of likes.
  * `likers: table::Table<address, bool>`: This is the clever part\! It's a table that maps a user's `address` to a boolean (`true`). We use this to efficiently check if a user has already liked the post, preventing any double-counting.

-----

## 🛠️ Public Functions

The module exposes two primary functions for interaction.

### `create_post`

This function initializes a new post and stores it under the caller's account.

```rust
public fun create_post(owner: &signer, post_id: u64)
```

  * **Purpose**: To create a new, empty post resource.
  * **Parameters**:
      * `owner: &signer`: The signer object of the account creating the post. This proves ownership.
      * `post_id: u64`: A unique ID for the new post.
  * **Action**: It creates a `Post` instance with `0` likes and a new empty `likers` table, then uses `move_to` to publish it to the `owner`'s account storage.

### `like_post`

This function allows any user to like an existing post.

```rust
public fun like_post(user: &signer, post_owner: address) acquires Post
```

  * **Purpose**: To add a like to a specified post.
  * **Parameters**:
      * `user: &signer`: The signer object of the account that is liking the post.
      * `post_owner: address`: The address of the account that owns the post to be liked.
  * **Action**:
    1.  It mutably borrows the `Post` resource from the `post_owner`'s account.
    2.  It checks if the `user`'s address is already in the `likers` table. If yes, it does nothing.
    3.  If not, it adds the `user`'s address to the `likers` table and increments the `likes` counter by 1.

-----

## 📖 How to Use: Example Workflow

1.  **Alice creates a post**: Alice calls `create_post` with her signer and a unique ID, say `101`. A `Post` resource is now stored under her account.
    > `MyModule::LikeSystem::create_post(&alice, 101)`
2.  **Bob likes Alice's post**: Bob sees Alice's post and decides to like it. He calls `like_post`, providing his signer and Alice's public address.
    > `MyModule::LikeSystem::like_post(&bob, @alice_address)`
3.  **State Change**: The `Post` resource under Alice's account is updated. Its `likes` count becomes `1`, and Bob's address is added to the `likers` table.
4.  **Bob tries to like it again**: If Bob accidentally calls `like_post` on Alice's post a second time, the function checks the `likers` table, sees his address, and returns immediately without making any changes.

-----

## 📜 Full Module Code

Here is the complete source code for the `LikeSystem` module.

```move
module MyModule::LikeSystem {

    use std::signer;
    use aptos_std::table::{Self, Table};

    /// Represents a post that can be liked.
    /// It is stored as a resource under the post owner's account.
    struct Post has store, key {
        id: u64,
        likes: u64,
        likers: Table<address, bool>,
    }

    /// Creates a new Post resource and moves it to the owner's account.
    /// The post is initialized with 0 likes.
    public fun create_post(owner: &signer, post_id: u64) {
        let likers_table = table::new<address, bool>();
        let post = Post {
            id: post_id,
            likes: 0,
            likers: likers_table,
        };
        // Move the Post resource to the owner's account storage
        move_to(owner, post);
    }

    /// Allows a user to like a post.
    /// Acquires a mutable reference to the Post resource to update its state.
    /// If the user has already liked the post, the function returns early.
    public fun like_post(user: &signer, post_owner: address) acquires Post {
        let post = borrow_global_mut<Post>(post_owner);
        let user_addr = signer::address_of(user);

        // Check if the user has already liked the post to prevent double-liking.
        if (table::contains(&post.likers, user_addr)) {
            return; // Already liked, do nothing.
        };

        // Add the user to the likers table and increment the like counter.
        table::add(&mut post.likers, user_addr, true);
        post.likes = post.likes + 1;
    }
}
```

-----

## 💡 Future Improvements

This module is a great foundation. Here are some ideas for extending its functionality:

  * **`unlike_post` Function**: Add a function to allow users to remove their like.
  * **Post Content**: Modify the `Post` struct to include an `string` field to store actual text content.
  * **On-Chain Events**: Emit events using `aptos_framework::event` when a post is created or liked. This makes it much easier for off-chain indexers and front-ends to track activity.
  * **Getter Function**: Add a public `view` function to read the number of likes for a post without needing write access.
