#![no_std]
use soroban_sdk::{
    contract, contractimpl, contracttype, token, Address, BytesN, Env, FromVal, Map, String,
    Symbol, TryIntoVal, Vec,
};


#[contracttype]
#[derive(Clone)]
pub struct TableMembership {
    member: Address,
    joined_at: u64,
    is_admin: bool,
}

#[contracttype]
#[derive(Clone)]
pub struct User {
    profile_nft: Address,
    avatar_uri: String,
    reputation: u32,
    is_active: bool,
}

#[contracttype]
#[derive(Clone)]
pub struct Artist {
    user_id: Address,
    artist_name: String,
    revenue_balance: i128,
    verified: bool,
}

#[contracttype]
#[derive(Clone)]
pub struct JukeboxTable {
    table_id: BytesN<32>,
    name: String,
    owner: Address,
    current_track: Option<BytesN<32>>,
    queue: Vec<BytesN<32>>,
    skip_votes: Map<Address, bool>,
    skip_threshold: u32,
    price_multiplier: u32,
    member_count: u32,
    is_active: bool,
}

#[contracttype]
#[derive(Clone)]
pub struct Track {
    track_id: BytesN<32>,
    track_nft: Address,
    title: String,
    artist_id: Address,
    collaborators: Vec<Address>,
    play_count: u32,
    base_price: i128,
    licenses_remaining: u32,
    metadata_uri: String,
    royalty_split: Vec<(Address, u32)>,
}

#[contracttype]
#[derive(Clone)]
pub struct TrackRequest {
    request_id: BytesN<32>,
    requester: Address,
    track_id: BytesN<32>,
    table_id: BytesN<32>,
    timestamp: u64,
    amount_paid: i128,
}

#[contracttype]
pub enum ContractEvent {
    TrackMinted(BytesN<32>),
    TrackRequested(BytesN<32>),
    TableCreated(BytesN<32>),
    MembershipChanged(BytesN<32>, Address, bool, bool),
    AdminChanged(BytesN<32>, Address, bool),
    TableStatusChanged(BytesN<32>, bool),
    SkipVoted(BytesN<32>, Address),
}

#[contracttype]
enum DataKey {
    Admin,
    UserCounter,
    TokenStellar,
    Users(Address),
    Artists(Address),
    Tracks(BytesN<32>),
    Tables(BytesN<32>),
    Requests(BytesN<32>),
    UserToNft(Address),
    NftToUser(Address),
    PlatformFee,
    TrackIdCounter,
    TableIdCounter,
    RequestIdCounter,
}

#[contract]
pub struct MetaJuke;

#[contractimpl]
impl MetaJuke {
    pub fn initialize(env: Env, admin: Address, token_stellar: Address, platform_fee: u32) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Contract already initialized");
        }

        admin.require_auth();

        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage()
            .instance()
            .set(&DataKey::TokenStellar, &token_stellar);
        env.storage()
            .instance()
            .set(&DataKey::PlatformFee, &platform_fee);
        env.storage()
            .instance()
            .set(&DataKey::TrackIdCounter, &0u32);
        env.storage()
            .instance()
            .set(&DataKey::TableIdCounter, &0u32);
        env.storage()
            .instance()
            .set(&DataKey::RequestIdCounter, &0u32);
        env.storage().instance().set(&DataKey::UserCounter, &0u32);
    }

    pub fn update_platform_fee(env: Env, new_fee: u32) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();

        if new_fee > 2000 {
            panic!("Fee too high");
        }

        env.storage()
            .instance()
            .set(&DataKey::PlatformFee, &new_fee);
    }

    pub fn register_user(env: Env, user: Address, profile_nft: Address, avatar_uri: String) {
        user.require_auth();

        if !Self::verify_nft_ownership(&env, &user, &profile_nft) {
            panic!("User doesn't own the NFT");
        }

        if env.storage().instance().has(&DataKey::Users(user.clone())) {
            panic!("User already registered");
        }

        if env
            .storage()
            .instance()
            .has(&DataKey::NftToUser(profile_nft.clone()))
        {
            panic!("NFT already associated with another user");
        }

        let new_user = User {
            profile_nft: profile_nft.clone(),
            avatar_uri,
            reputation: 100,
            is_active: true,
        };

        env.storage()
            .instance()
            .set(&DataKey::Users(user.clone()), &new_user);
        env.storage()
            .instance()
            .set(&DataKey::UserToNft(user.clone()), &profile_nft);
        env.storage()
            .instance()
            .set(&DataKey::NftToUser(profile_nft), &user);
    }

    pub fn register_artist(env: Env, user: Address, artist_name: String) {
        user.require_auth();

        if !env.storage().instance().has(&DataKey::Users(user.clone())) {
            panic!("User not registered");
        }

        if env
            .storage()
            .instance()
            .has(&DataKey::Artists(user.clone()))
        {
            panic!("Already registered as artist");
        }

        let new_artist = Artist {
            user_id: user.clone(),
            artist_name,
            revenue_balance: 0,
            verified: false,
        };

        env.storage()
            .instance()
            .set(&DataKey::Artists(user), &new_artist);
    }

    pub fn update_user_profile(env: Env, user: Address, avatar_uri: String) {
        user.require_auth();

        let mut user_data: User = env
            .storage()
            .instance()
            .get(&DataKey::Users(user.clone()))
            .unwrap();

        user_data.avatar_uri = avatar_uri;
        env.storage()
            .instance()
            .set(&DataKey::Users(user), &user_data);
    }

    pub fn mint_track(
        env: Env,
        artist: Address,
        title: String,
        base_price: i128,
        licenses: u32,
        metadata_uri: String,
        collaborators: Vec<Address>,
        royalty_split: Vec<(Address, u32)>,
    ) -> BytesN<32> {
        artist.require_auth();

        if !env
            .storage()
            .instance()
            .has(&DataKey::Artists(artist.clone()))
        {
            panic!("Not registered as artist");
        }

        let mut total_split = 0;
        for (_, percentage) in royalty_split.iter() {
            total_split += percentage;
        }
        if total_split != 100 {
            panic!("Royalty splits must total 100%");
        }

        let mut track_counter: u32 = env
            .storage()
            .instance()
            .get(&DataKey::TrackIdCounter)
            .unwrap();
        track_counter += 1;

        let track_id_str = String::from_str(&env, "track_");
        let track_id_bytes: BytesN<32> = BytesN::from_val(&env, &track_id_str.to_val());
        track_id_bytes.copy_into_slice(
            track_counter
                .to_be_bytes()
                .as_mut_slice()
                .try_into()
                .unwrap(),
        );
        let track_id: BytesN<32> = env.crypto().sha256((&track_id_bytes).as_ref()).into();

        let track_nft_str = String::from_str(&env, "track_nft_");
        let track_nft_id_bytes = BytesN::from_val(&env, &track_nft_str.to_val());
        track_nft_id_bytes.copy_into_slice(&mut track_counter.to_be_bytes());
        let track_nft =
            Address::from_string_bytes(<BytesN<32> as AsRef<soroban_sdk::Bytes>>::as_ref(
                &BytesN::from_val(&env, &track_nft_id_bytes.to_val()),
            ));

        let new_track = Track {
            track_id: track_id.clone(),
            track_nft,
            title,
            artist_id: artist.clone(),
            collaborators,
            play_count: 0,
            base_price,
            licenses_remaining: licenses,
            metadata_uri,
            royalty_split,
        };

        env.storage()
            .instance()
            .set(&DataKey::Tracks(track_id.clone()), &new_track);
        env.storage().instance().set(
            &DataKey::ArtistTracks(artist.clone(), track_id.clone()),
            &true,
        );
        env.storage()
            .instance()
            .set(&DataKey::TrackIdCounter, &track_counter);

        env.events()
            .publish((Symbol::new(&env, "track_minted"), track_id.clone()), ());

        track_id
    }

    pub fn update_track(
        env: Env,
        artist: Address,
        track_id: BytesN<32>,
        new_base_price: i128,
        new_licenses: u32,
        new_metadata_uri: String,
    ) {
        artist.require_auth();

        let mut track: Track = env
            .storage()
            .instance()
            .get(&DataKey::Tracks(track_id.clone()))
            .unwrap();

        if track.artist_id != artist {
            panic!("Not track owner");
        }

        track.base_price = new_base_price;
        track.licenses_remaining = new_licenses;
        track.metadata_uri = new_metadata_uri;

        env.storage()
            .instance()
            .set(&DataKey::Tracks(track_id), &track);
    }

    pub fn create_table(
        env: Env,
        owner: Address,
        name: String,
        skip_threshold: u32,
        price_multiplier: u32,
    ) -> BytesN<32> {
        owner.require_auth();

        if !env.storage().instance().has(&DataKey::Users(owner.clone())) {
            panic!("User not registered");
        }

        let mut table_counter: u32 = env
            .storage()
            .instance()
            .get(&DataKey::TableIdCounter)
            .unwrap();
        table_counter += 1;

        let table_id_str: String = String::from_str(&env, "table_");
        let table_id_bytes: BytesN<32> = BytesN::from_val(&env, table_id_str.as_val());
        let _ = &mut owner
            .to_string()
            .copy_into_slice(table_id_bytes.to_array().as_mut());
        table_id_bytes.copy_into_slice(
            &mut table_counter
                .to_be_bytes()
                .as_mut_slice()
                .try_into()
                .unwrap(),
        );
        let table_id: BytesN<32> = env.crypto().sha256((&table_id_bytes).as_ref()).into();

        let new_table = JukeboxTable {
            table_id: table_id.clone(),
            name,
            owner: owner.clone(),
            current_track: None,
            queue: Vec::new(&env),
            skip_votes: Map::new(&env),
            skip_threshold,
            price_multiplier,
            member_count: 0,
            is_active: true,
        };

        env.storage()
            .instance()
            .set(&DataKey::Tables(table_id.clone()), &new_table);
        env.storage()
            .instance()
            .set(&DataKey::TableIdCounter, &table_counter);

        env.events()
            .publish((Symbol::new(&env, "table_created"), table_id.clone()), ());

        table_id
    }

    pub fn update_table(
        env: Env,
        owner: Address,
        table_id: BytesN<32>,
        name: String,
        skip_threshold: u32,
        price_multiplier: u32,
    ) {
        owner.require_auth();

        let mut table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.owner != owner {
            panic!("Not table owner");
        }

        table.name = name;
        table.skip_threshold = skip_threshold;
        table.price_multiplier = price_multiplier;

        env.storage()
            .instance()
            .set(&DataKey::Tables(table_id), &table);
    }

    pub fn request_track(
        env: Env,
        requester: Address,
        track_id: BytesN<32>,
        table_id: BytesN<32>,
    ) -> BytesN<32> {
         // VERIFYING TABLE'S EXISTENCE
    if !env.storage().has(&table_id) {
        panic!("table does not exist");
    }
    // verifying if user has permission 
    let table_owner: Address = env.storage().get(&table_id).unwrap().unwrap();
    if requester != table_owner {
        panic!("requester is not the table owner");
    }
    // Generating a unique request ID [combining table_id + track_id + random component] , like concat them . 
    let mut reqid_data = Bytes::new(&env);
    reqid_data.append(&table_id.clone().into());
    reqid_data .append(&track_id.clone().into());
    reqid_data .append(&env.prng().gen::<BytesN<16>>().into());
    let request_id = env.crypto().sha256(&reqid_data );
    // STORING REQUEST DETAILS 
    let request_key = DataKey::Request(request_id.clone());
    let request = TrackRequest {
        requester,
        track_id,
        table_id,
        fulfilled: false,
    };
    env.storage().set(&request_key, &request);
        request_id
    }

    pub fn vote_to_skip(env: Env, user: Address, table_id: BytesN<32>) -> bool {
        user.require_auth();

        if !env.storage().instance().has(&DataKey::Users(user.clone())) {
            panic!("User not registered");
        }

        let mut table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.current_track.is_none() {
            panic!("No track currently playing");
        }

        table.skip_votes.set(user.clone(), true);
        let vote_count = table.skip_votes.values().into_iter().filter(|&v| v).count();
        let should_skip = vote_count >= table.skip_threshold as usize;

        if should_skip {
            Self::advance_queue(&env, table_id.clone());
            table.skip_votes = Map::new(&env);
            env.storage()
                .instance()
                .set(&DataKey::Tables(table_id), &table);
            true
        } else {
            env.storage()
                .instance()
                .set(&DataKey::Tables(table_id), &table);
            false
        }
    }

    pub fn advance_queue(env: &Env, table_id: BytesN<32>) -> Option<BytesN<32>> {
        let mut table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.queue.is_empty() {
            table.current_track = None;
            env.storage()
                .instance()
                .set(&DataKey::Tables(table_id.clone()), &table);
            return None;
        }

        let next_track = table.queue.pop_front().unwrap();
        table.current_track = Some(next_track.clone());
        table.skip_votes = Map::new(env);
        env.storage()
            .instance()
            .set(&DataKey::Tables(table_id.clone()), &table);

        Some(next_track)
    }

    fn distribute_royalties(env: &Env, track: &Track, payment_amount: &i128) {
        let platform_fee: u32 = env.storage().instance().get(&DataKey::PlatformFee).unwrap();

        let fee_amount = (payment_amount * platform_fee as i128) / 10000;
        let royalty_amount = payment_amount - fee_amount;

        let token_address: Address = env
            .storage()
            .instance()
            .get(&DataKey::TokenStellar)
            .unwrap();
        let token_client = token::Client::new(env, &token_address);

        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        token_client.transfer(&env.current_contract_address(), &admin, &fee_amount);

        for (artist_address, percentage) in track.royalty_split.iter() {
            let artist_share = (royalty_amount * (percentage as i128)) / 100;

            if env
                .storage()
                .instance()
                .has(&DataKey::Artists(artist_address.clone()))
            {
                let mut artist: Artist = env
                    .storage()
                    .instance()
                    .get(&DataKey::Artists(artist_address.clone()))
                    .unwrap();
                artist.revenue_balance += artist_share;
                env.storage()
                    .instance()
                    .set(&DataKey::Artists(artist_address.clone()), &artist);
            }

            token_client.transfer(
                &env.current_contract_address(),
                &artist_address,
                &artist_share,
            );
        }
    }

    pub fn withdraw_revenue(env: Env, artist: Address) -> i128 {
        artist.require_auth();

        if !env
            .storage()
            .instance()
            .has(&DataKey::Artists(artist.clone()))
        {
            panic!("Not registered as artist");
        }

        let mut artist_data: Artist = env
            .storage()
            .instance()
            .get(&DataKey::Artists(artist.clone()))
            .unwrap();

        let amount = artist_data.revenue_balance;
        artist_data.revenue_balance = 0;
        env.storage()
            .instance()
            .set(&DataKey::Artists(artist.clone()), &artist_data);

        let token_address: Address = env
            .storage()
            .instance()
            .get(&DataKey::TokenStellar)
            .unwrap();
        let token_client = token::Client::new(&env, &token_address);

        token_client.transfer(&env.current_contract_address(), &artist, &amount);

        amount
    }

    fn verify_nft_ownership(env: &Env, user: &Address, nft_address: &Address) -> bool {
       
    }

    
    pub fn get_user(env: Env, user: Address) -> Option<User> {
        env.storage().instance().get(&DataKey::Users(user))
    }

    pub fn get_artist(env: Env, artist: Address) -> Option<Artist> {
        env.storage().instance().get(&DataKey::Artists(artist))
    }

    pub fn get_track(env: Env, track_id: BytesN<32>) -> Option<Track> {
        env.storage().instance().get(&DataKey::Tracks(track_id))
    }

    pub fn get_table(env: Env, table_id: BytesN<32>) -> Option<JukeboxTable> {
        env.storage().instance().get(&DataKey::Tables(table_id))
    }

    pub fn get_queue(env: Env, table_id: BytesN<32>) -> Vec<BytesN<32>> {
        if let Some(table) = Self::get_table(env.clone(), table_id) {
            table.queue
        } else {
            Vec::new(&env)
        }
    }

    pub fn is_table_member(env: Env, user: Address, table_id: BytesN<32>) -> bool {
        env.storage()
            .instance()
            .has(&DataKey::TableMembers(table_id, user))
    }

    pub fn is_table_admin(env: Env, user: Address, table_id: BytesN<32>) -> bool {
        env.storage()
            .instance()
            .has(&DataKey::TableAdmins(table_id, user))
    }

    pub fn get_table_member_count(env: Env, table_id: BytesN<32>) -> u32 {
        if let Some(table) = Self::get_table(env, table_id) {
            table.member_count
        } else {
            0
        }
    }

    pub fn join_table(env: Env, user: Address, table_id: BytesN<32>) {
        user.require_auth();

        if !env.storage().instance().has(&DataKey::Users(user.clone())) {
            panic!("User not registered");
        }

        let mut table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap_or_else(|| panic!("Table not found"));

        if !table.is_active {
            panic!("Table is closed");
        }

        if env
            .storage()
            .instance()
            .has(&DataKey::TableMembers(table_id.clone(), user.clone()))
        {
            panic!("Already a member of this table");
        }
        let mut members: Vec<Address> = env
            .storage()
            .instance()
            .get(&DataKey::TableMemberList(table_id.clone()))
            .unwrap_or_else(|| Vec::new(&env));

        if !members.contains(&user) {
            members.push_back(user.clone());
            env.storage()
                .instance()
                .set(&DataKey::TableMemberList(table_id.clone()), &members);
        }

        let membership = TableMembership {
            member: user.clone(),
            joined_at: env.ledger().timestamp(),
            is_admin: false,
        };

        env.storage().instance().set(
            &DataKey::TableMembers(table_id.clone(), user.clone()),
            &membership,
        );

        env.storage()
            .instance()
            .set(&DataKey::UserTables(user.clone(), table_id.clone()), &true);

        table.member_count += 1;
        env.storage()
            .instance()
            .set(&DataKey::Tables(table_id.clone()), &table);

        env.events().publish(
            (Symbol::new(&env, "membership_changed"), table_id.clone()),
            (user, true, false),
        );
    }

    pub fn leave_table(env: Env, user: Address, table_id: BytesN<32>) {
      

    }

    pub fn add_table_admin(env: Env, owner: Address, table_id: BytesN<32>, new_admin: Address) {
        owner.require_auth();

        let table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.owner != owner {
            panic!("Not table owner");
        }

        let admin_membership = TableMembership {
            member: new_admin.clone(),
            joined_at: env.ledger().timestamp(),
            is_admin: true,
        };

        env.storage().instance().set(
            &DataKey::TableMembers(table_id.clone(), new_admin.clone()),
            &admin_membership,
        );
        env.storage()
            .instance()
            .set(&DataKey::TableAdmins(table_id, new_admin), &true);
    }

    pub fn remove_table_admin(env: Env, owner: Address, table_id: BytesN<32>, admin: Address) {
        owner.require_auth();

        let table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.owner != owner {
            panic!("Not table owner");
        }

        env.storage()
            .instance()
            .remove(&DataKey::TableAdmins(table_id.clone(), admin.clone()));

        let membership = TableMembership {
            member: admin.clone(),
            joined_at: env.ledger().timestamp(),
            is_admin: false,
        };

        env.storage()
            .instance()
            .set(&DataKey::TableMembers(table_id, admin), &membership);
    }

    pub fn set_table_status(env: Env, owner: Address, table_id: BytesN<32>, active: bool) {
        owner.require_auth();

        let mut table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.owner != owner {
            panic!("Not table owner");
        }

        table.is_active = active;

        if !active {
            table.queue = Vec::new(&env);
            table.current_track = None;
        }

        env.storage()
            .instance()
            .set(&DataKey::Tables(table_id.clone()), &table);

        env.events().publish(
            (Symbol::new(&env, "table_status_changed"), table_id),
            active,
        );
    }

    pub fn has_voted_to_skip(env: Env, user: Address, table_id: BytesN<32>) -> bool {
        let table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id))
            .unwrap();

        table.skip_votes.get(user).unwrap_or(false)
    }

    pub fn advance_queue_public(
        env: Env,
        caller: Address,
        table_id: BytesN<32>,
    ) -> Option<BytesN<32>> {
        caller.require_auth();

        let table: JukeboxTable = env
            .storage()
            .instance()
            .get(&DataKey::Tables(table_id.clone()))
            .unwrap();

        if table.owner != caller {
            let membership: TableMembership = env
                .storage()
                .instance()
                .get(&DataKey::TableMembers(table_id.clone(), caller))
                .unwrap_or_else(|| panic!("Not authorized"));

            if !membership.is_admin {
                panic!("Not authorized");
            }
        }

        Self::advance_queue(&env, table_id)
    }

    pub fn get_total_tracks(env: Env) -> u32 {
        env.storage()
            .instance()
            .get(&DataKey::TrackIdCounter)
            .unwrap_or(0)
    }
    pub fn get_total_tables(env: Env) -> u32 {
        env.storage()
            .instance()
            .get(&DataKey::TableIdCounter)
            .unwrap_or(0)
    }
    pub fn get_total_requests(env: Env) -> u32 {
        env.storage()
            .instance()
            .get(&DataKey::RequestIdCounter)
            .unwrap_or(0)
    }

    pub fn get_platform_stats(env: Env) -> (u32, u32, u32) {
        let total_tracks = Self::get_total_tracks(env.clone());
        let total_tables = env
            .storage()
            .instance()
            .get(&DataKey::TableIdCounter)
            .unwrap_or(0);
        let total_requests = env
            .storage()
            .instance()
            .get(&DataKey::RequestIdCounter)
            .unwrap_or(0);

        (total_tracks, total_tables, total_requests)
    }
    pub fn get_artist_tracks(env: Env, artist: Address) -> Vec<BytesN<32>> {
        let mut tracks = Vec::new(&env);
        let artist_data: Artist = env
            .storage()
            .instance()
            .get(&DataKey::Artists(artist.clone()))
            .unwrap_or_else(|| panic!("Artist not found"));

        
        let track_counter: u32 = env
            .storage()
            .instance()
            .get(&DataKey::TrackIdCounter)
            .unwrap_or(0);

        for i in 1..=track_counter {
            if env.storage().instance().has(&DataKey::ArtistTracks(
                artist.clone(),
                BytesN::from_array(&env, &[i as u8; 32]),
            )) {
                tracks.push_back(BytesN::from_array(&env, &[i as u8; 32]));
            }
        }
        tracks
    }
    pub fn get_user_tables(env: Env, user: Address) -> Vec<BytesN<32>> {
        let mut tables = Vec::new(&env);
        let table_counter: u32 = env
            .storage()
            .instance()
            .get(&DataKey::TableIdCounter)
            .unwrap_or(0);

        for i in 1..=table_counter {
            let table_id = BytesN::from_array(&env, &[i as u8; 32]);
            if env
                .storage()
                .instance()
                .has(&DataKey::TableMembers(table_id.clone(), user.clone()))
            {
                tables.push_back(table_id);
            }
        }
        tables
    }
  
    
    
    pub fn get_table_members(env: Env, table_id: BytesN<32>) -> Vec<Address> {
        let mut members = Vec::new(&env);

        
        if !env
            .storage()
            .instance()
            .has(&DataKey::Tables(table_id.clone()))
        {
            panic!("Table not found");
        }  
        
        

        
        
        if let Some(members_list) = env
            .storage()
            .instance()
            .get(&DataKey::TableMemberList(table_id.clone()))
        {
            return members_list;
        }

        members
    }

    pub fn get_table_requests(env: Env, table_id: BytesN<32>) -> Vec<TrackRequest> {
      
    }

    
    pub fn update_artist_verification(env: Env, admin: Address, artist: Address, verified: bool) {
        let stored_admin: Address = env
            .storage()
            .instance()
            .get(&DataKey::Admin)
            .unwrap_or_else(|| panic!("Admin not set"));

        if admin != stored_admin {
            panic!("Not authorized");
        }

        let mut artist_data: Artist = env
            .storage()
            .instance()
            .get(&DataKey::Artists(artist.clone()))
            .unwrap_or_else(|| panic!("Artist not found"));

        artist_data.verified = verified;
        env.storage()
            .instance()
            .set(&DataKey::Artists(artist), &artist_data);
    }
}
