class DatabaseHelper{
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor to return the singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  // Example method to demonstrate functionality
  void connect() {
    print("Connected to the database.");
  }
}