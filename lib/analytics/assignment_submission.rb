module Analytics
  class AssignmentSubmission
    attr_reader :assignment, :submission

    def initialize(assignment, submission = nil)
      @assignment, @submission = assignment, submission
    end

    def recorded?
      !!recorded_at
    end

    def recorded_at
      if !@submission || @submission.missing?
        # if the submission is missing or does not exist return nil
        # because the student has not submitted anything for the assignment.
        nil
      elsif submitted_at || @assignment.expects_submission?
        # if the assignment has been submitted return the submitted_at date.
        # if we expect a submission return submitted_at because canvas expects a
        # submission to be submitted.
        submitted_at
      elsif graded_at.nil? || (@submission.graded? && @submission.score == 0)
        # if graded_at is nil we know that due_at is in the future.  We know it
        # must be in the future because @submission.missing? above would have
        # been true.  With due_at in the future, means it has not been recorded yet.
        # if the submission has been graded at a grade of zero it has not been
        # submitted yet even if it has been graded.
        nil
      elsif due_at.nil?
        # if due_at is nil and we know graded_at is not nil so return that.
        graded_at
      elsif graded_at < due_at
        # if graded_at is before due_at return graded_at which is the oldest date
        graded_at
      else
        # if due_at is before graded_at return due_at which is the oldest date
        due_at
      end
    end

    def due_at
      return @submission.cached_due_date if @submission
      @assignment.due_at
    end

    def missing?
      status == :missing
    end

    def late?
      status == :late
    end

    def on_time?
      status == :on_time
    end

    def floating?
      status == :floating
    end

    def status
      @submitted_status ||= submitted_status
    end

    def score
      @submission.score.to_f if @submission && @submission.try(:score)
    end

    def graded?
      @submission && @submission.graded?
    end

    def graded_at
      @submission.graded_at if graded?
    end

    def submitted_at
      @submission.submitted_at if @submission
    end

    private

    def submitted_status
      # If the submission does not exist then assume there are no overrides
      # and use the assignments date due.  The DueDateCacher should cache due
      # dates if they are overridden.
      if !@submission
        if @assignment.overdue?
          :missing
        else
          :floating
        end
      elsif @submission.missing?
        :missing
      elsif @submission.late?
        :late
      elsif recorded?
        :on_time
      else
        :floating
      end
    end
  end
end