class User < SqlParent
  attr_accessor :fname, :lname, :id
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM users")
    results.map { |result| User.new(result) }
  end

  def self.table_name
    'users'
  end

  def self.find_by_name(fname, lname)
    user_hash = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT *
      FROM
        users
      WHERE
        fname=? AND lname = ?;
    SQL

    if user_hash.empty?
      return nil
    else
      User.new(user_hash[0])
    end
  end

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def to_s
    "#{@fname} #{@lname}"
  end

  def authored_questions
    results = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT *
      FROM
        questions
      WHERE
        user_id=?
    SQL
    results.map { |result| Question.new(result) }
  end

  def authored_replies
    results = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT *
      FROM
        replies
      WHERE
        user_id=?
    SQL
    results.map { |result| Reply.new(result) }

  end

  def followed_questions
    QuestionFollowers.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def avg_karma
    results = QuestionsDatabase.instance.execute(<<-SQL, @id, @id)
    SELECT (COUNT(questions.id) *1.0/ (SELECT COUNT(*) FROM questions WHERE user_id = ?))
    FROM questions JOIN question_likes ON (question_likes.question_id = questions.id)
    WHERE questions.user_id = ?
    SQL
    results[0].values[0]
  end

  def save
    params = [self.fname, self.lname]
    if self.id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *params)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?)
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, *params)
        UPDATE users
        SET fname = ?, lname = ?
        WHERE id = #{@id}

      SQL

    end
  end

end