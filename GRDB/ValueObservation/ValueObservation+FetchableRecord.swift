extension FetchRequest where RowDecoder: FetchableRecord {
    
    // MARK: - Observation
    
    /// Creates a ValueObservation which observes *request*, and notifies
    /// fresh records whenever the request is modified by a
    /// database transaction.
    ///
    /// For example:
    ///
    ///     let request = Player.all()
    ///     let observation = request.observationForAll()
    ///
    ///     let observer = try observation.start(in: dbQueue) { players: [Player] in
    ///         print("Players have changed")
    ///     }
    ///
    /// The returned observation has the default configuration:
    ///
    /// - When started with the `start(in:onError:onChange:)` method, a fresh
    /// value is immediately notified on the main queue.
    /// - Upon subsequent database changes, fresh values are notified on the
    /// main queue.
    /// - The observation lasts until the observer returned by
    /// `start` is deallocated.
    ///
    /// - returns: a ValueObservation.
    public func observationForAll() -> ValueObservation<ValueReducers.AllRecords<RowDecoder>> {
        ValueObservation.tracking(self, reducer: { _ in
            ValueReducers.AllRecords { try Row.fetchAll($0, self) }
        })
    }
    
    /// Creates a ValueObservation which observes *request*, and notifies a
    /// fresh record whenever the request is modified by a database transaction.
    ///
    /// For example:
    ///
    ///     let request = Player.filter(key: 1)
    ///     let observation = request.observationForFirst()
    ///
    ///     let observer = try observation.start(in: dbQueue) { player: Player? in
    ///         print("Player has changed")
    ///     }
    ///
    /// The returned observation has the default configuration:
    ///
    /// - When started with the `start(in:onError:onChange:)` method, a fresh
    /// value is immediately notified on the main queue.
    /// - Upon subsequent database changes, fresh values are notified on the
    /// main queue.
    /// - The observation lasts until the observer returned by
    /// `start` is deallocated.
    ///
    /// - returns: a ValueObservation.
    public func observationForFirst() -> ValueObservation<ValueReducers.OneRecord<RowDecoder>> {
        ValueObservation.tracking(self, reducer: { _ in
            ValueReducers.OneRecord { try Row.fetchOne($0, self) }
        })
    }
}

extension TableRecord where Self: FetchableRecord {
    
    // MARK: - Observation
    
    /// Creates a ValueObservation which observes the record table, and notifies
    /// fresh records whenever the request is modified by a
    /// database transaction.
    ///
    /// For example:
    ///
    ///     let observation = Player.observationForAll()
    ///
    ///     let observer = try observation.start(in: dbQueue) { players: [Player] in
    ///         print("Players have changed")
    ///     }
    ///
    /// The returned observation has the default configuration:
    ///
    /// - When started with the `start(in:onError:onChange:)` method, a fresh
    /// value is immediately notified on the main queue.
    /// - Upon subsequent database changes, fresh values are notified on the
    /// main queue.
    /// - The observation lasts until the observer returned by
    /// `start` is deallocated.
    ///
    /// - returns: a ValueObservation.
    public static func observationForAll() -> ValueObservation<ValueReducers.AllRecords<Self>> {
        all().observationForAll()
    }
    
    /// Creates a ValueObservation which observes the table record, and notifies
    /// a fresh record whenever the request is modified by a
    /// database transaction.
    ///
    /// For example:
    ///
    ///     let observation = Player.observationForFirst()
    ///
    ///     let observer = try observation.start(in: dbQueue) { player: Player? in
    ///         print("Player has changed")
    ///     }
    ///
    /// The returned observation has the default configuration:
    ///
    /// - When started with the `start(in:onError:onChange:)` method, a fresh
    /// value is immediately notified on the main queue.
    /// - Upon subsequent database changes, fresh values are notified on the
    /// main queue.
    /// - The observation lasts until the observer returned by
    /// `start` is deallocated.
    ///
    /// - returns: a ValueObservation.
    public static func observationForFirst() -> ValueObservation<ValueReducers.OneRecord<Self>> {
        // TODO: check that limit(1) has no impact on requests like filter(key:)
        return limit(1).observationForFirst()
    }
}

extension ValueReducers {
    /// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
    ///
    /// A reducer which outputs arrays of records, filtering out consecutive
    /// identical database rows.
    ///
    /// :nodoc:
    public struct AllRecords<RowDecoder>: ValueReducer
        where RowDecoder: FetchableRecord
    {
        private let _fetch: (Database) throws -> [Row]
        private var previousRows: [Row]?
        
        init(fetch: @escaping (Database) throws -> [Row]) {
            self._fetch = fetch
        }
        
        public func fetch(_ db: Database) throws -> [Row] {
            try _fetch(db)
        }
        
        public mutating func value(_ rows: [Row]) -> [RowDecoder]? {
            if let previousRows = previousRows, previousRows == rows {
                // Don't notify consecutive identical row arrays
                return nil
            }
            self.previousRows = rows
            return rows.map(RowDecoder.init(row:))
        }
    }
    
    /// [**Experimental**](http://github.com/groue/GRDB.swift#what-are-experimental-features)
    ///
    /// A reducer which outputs optional records, filtering out consecutive
    /// identical database rows.
    ///
    /// :nodoc:
    public struct OneRecord<RowDecoder>: ValueReducer
        where RowDecoder: FetchableRecord
    {
        private let _fetch: (Database) throws -> Row?
        private var previousRow: Row??
        
        init(fetch: @escaping (Database) throws -> Row?) {
            self._fetch = fetch
        }
        
        public func fetch(_ db: Database) throws -> Row? {
            try _fetch(db)
        }
        
        public mutating func value(_ row: Row?) -> RowDecoder?? {
            if let previousRow = previousRow, previousRow == row {
                // Don't notify consecutive identical rows
                return nil
            }
            self.previousRow = row
            return .some(row.map(RowDecoder.init(row:)))
        }
    }
}
