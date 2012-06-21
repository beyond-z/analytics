
# intended for inclusion in analytics' various controllers for shared
# functionality around permissions
module AnalyticsPermissions
  module ClassMethods
  end

  module InstanceMethods
    def require_analytics_enabled
      # does the account even have analytics enabled?
      raise ActiveRecord::RecordNotFound unless service_enabled?(:analytics)
      return true
    end

    def require_analytics_for_department
      # do you have permission to use them?
      account_scope = Account.active
      @account = api_request? ? api_find(account_scope, params[:account_id]) : account_scope.find(params[:account_id])
      return false unless authorized_action(@account, @current_user, :view_analytics)

      terms = @account.root_account.enrollment_terms.active
      if params[:term_id]
        # load the specific term, no filter
        @term = api_request? ? api_find(terms, params[:term_id]) : terms.find(params[:term_id])
        @filter = nil
      else
        # no term specified, use the default term
        @term = @account.root_account.default_enrollment_term
        if ['current', 'completed'].include?(params[:filter])
          # respect the requested filter on the default term
          @filter = params[:filter]
        elsif terms.count > 1
          # default behavior for multiple terms is default term, no filter
          @filter = nil
        else
          # default behavior for only one term is current courses filter
          @filter = 'current'
        end
      end

      @department_analytics = Analytics::Department.new(@current_user, session, @account, @term, @filter)
      return true
    end

    # returns true iff any analytics pages related to this course (whether
    # course or student in course) can be viewed by the current user.
    def require_course_with_analytics
      # do you have permission to use them?
      scope = Course.scoped(:conditions => {:workflow_state => ['available', 'completed']})
      @course = api_request? ? api_find(scope, params[:course_id]) : scope.find(params[:course_id])
      return false unless authorized_action(@course, @current_user, :view_analytics)

      @course_analytics = Analytics::Course.new(@current_user, session, @course)
      raise ActiveRecord::RecordNotFound unless @course_analytics.available?

      return true
    end

    # returns true iff the course's analytics page can be viewed by the current
    # user.
    def require_analytics_for_course
      return false unless require_course_with_analytics
      return authorized_action(@course, @current_user, :read_as_admin)
    end

    # returns true iff the student's analytics in the course page can be viewed
    # by the current user.
    def require_analytics_for_student_in_course
      return false unless require_course_with_analytics

      # you can use analytics and see this course, but do you have access to this
      # student's enrollment in the course?
      @student = api_request? ? api_find(User, params[:student_id]) : User.find(params[:student_id])

      @student_analytics = Analytics::StudentInCourse.new(@current_user, session, @course, @student)
      raise ActiveRecord::RecordNotFound unless @student_analytics.available?

      return false unless authorized_action(@student_analytics.enrollment, @current_user, :read_grades)

      return true
    end
  end

  def self.included(klass)
    klass.send :include, InstanceMethods
    klass.extend ClassMethods

    klass.before_filter :require_user # comes from ApplicationController
    klass.before_filter :require_analytics_enabled
  end
end
