require 'csv'
require 'gruff'
require 'linefit'
require 'fileutils'
require 'byebug'

def test_should_render_with_transparent_theme
    g = Gruff::Line.new(400)
    g.title = 'Transparent Background'
    g.theme = {
        :colors => %w(black grey),
        :marker_color => 'grey',
        :font_color => 'black',
        :background_colors => 'white'
    }

    g.labels = {
        0 => '5/6',
        1 => '5/15',
        2 => '5/24',
        3 => '5/30',
    }
    g.data(:apples, [-1, 0, 4, -4])
    g.data(:peaches, [10, 8, 6, 3])
    g.write('test.png')
end


class Homework
    attr_accessor :subject, :comprehension, :date
    def initialize(subject, comprehension, date)
        @subject=subject
        @comprehension=comprehension
        @date=date
    end
end


class Student
    attr_accessor :code, :gender, :homeworks, :grade
    # GRADE 2 CODES
    FREEMANGRADE2CODES=[*1..13]
    OLDROADGRADE2CODES=[*31..43]
    PARESGRADE2CODES=[*58..70]
    CEDARGRADE2CODES=[*82..104]
    SROLIVIAGRADE2CODES=[*129..149]
    VILLAGRADE2CODES=[*168..194]
    BUCKLEYSGRADE2CODES=[*280..298]
    GRADE2CODES=FREEMANGRADE2CODES+OLDROADGRADE2CODES+PARESGRADE2CODES+CEDARGRADE2CODES+SROLIVIAGRADE2CODES+VILLAGRADE2CODES+BUCKLEYSGRADE2CODES
    # GRADE 4 CODES
    FREEMANGRADE4CODES=[*13..31]
    OLDROADGRADE4CODES=[*43..58]
    PARESGRADE4CODES=[*70..82]
    CEDARGRADE4CODES=[*104..129]
    SROLIVIAGRADE4CODES=[*149..168]
    VILLAGRADE4CODES=[*194..215]
    BUCKLEYSGRADE4CODES=[*298..315]
    GRADE4CODES=FREEMANGRADE4CODES+OLDROADGRADE4CODES+PARESGRADE4CODES+CEDARGRADE4CODES+SROLIVIAGRADE4CODES+VILLAGRADE4CODES+BUCKLEYSGRADE4CODES

    def initialize(code, gender, homeworks=false)
        @code=code
        @gender=gender
        if homeworks
            @homeworks=homeworks 
        else
            @homeworks=[]
        end
        @grade=2 if GRADE2CODES.include? @code
        @grade=4 if GRADE4CODES.include? @code

    end

    def get_comp(grade, subject, date)
        @homeworks.each do |homework|
            return homework.comprehension if  @grade==grade && homework.subject==subject && homework.date==date
        end
        return 0
    end
end


class School
    attr_accessor :name, :students, :dates
    def initialize(name, generate_graphs=true)
        @name=name
        @students={}
        @dates=[]
        set_school_data
        generate_all_subject_grade_graphs if generate_graphs
    end

    def set_school_data(filename=false)
        filename=self.name+".csv" unless filename
        data=CSV.read(filename)
        row_num=0
        data.each do |student_data|
            set_student_data(student_data) unless row_num==0
            row_num+=1
        end
    end

    def set_student_data(student_data)
        code=student_data[1].to_i
        unless @students.key?(code)
            gender=student_data[2]
            student=Student.new(code, gender)
            @students[code]=student
        end
        set_homeworks(code, student_data)     
    end

    def set_homeworks(code,student_data)
        date=Date.strptime(student_data[3], '%m/%d/%Y')
        # pushing date to collection of dates
        @dates.push(date)

        # Setting Math Homework
        student_data[7].nil? ? math_comp=0 : math_comp=student_data[7].to_i
        math_homework=Homework.new("math", math_comp, date)
        # Setting English HOmeowrk
        add_homework_to_student(code, math_homework)
        student_data[11].nil? ? eng_comp=0 : eng_comp=student_data[11].to_i
        eng_homework=Homework.new("eng", eng_comp, date)
        add_homework_to_student(code, eng_homework)
    end 

    def add_homework_to_student(code, homework)
        @students[code].homeworks.push(homework)
    end

    def generate_all_subject_grade_graphs
        Dir.mkdir(@name+"Graphs") unless File.exists?(@name+"Graphs")
        generate_subject_grade_graph(@name+"Grade2MathMale.png",2,'math','m')
        generate_subject_grade_graph(@name+"Grade2MathFemale.png",2,'math','f')
        generate_subject_grade_graph(@name+"Grade2Math.png",2,'math')
        generate_subject_grade_graph(@name+"Grade2EngMale.png",2,'eng','m')
        generate_subject_grade_graph(@name+"Grade2EngFemale.png",2,'eng','f')
        generate_subject_grade_graph(@name+"Grade2Eng.png",2,'eng')
        generate_subject_grade_graph(@name+"Grade4MathMale.png",4,'math','m')
        generate_subject_grade_graph(@name+"Grade4MathFemale.png",4,'math','f')
        generate_subject_grade_graph(@name+"Grade4Math.png",4,'math')
        generate_subject_grade_graph(@name+"Grade4EngMale.png",4,'eng','m')
        generate_subject_grade_graph(@name+"Grade4MathFemale.png",4,'math','f')
        generate_subject_grade_graph(@name+"Grade4Math.png",4,'math')
    end


    def generate_subject_grade_graph(filename, grade, subject, gender=false)
        data=get_averages(grade, subject, gender)
        unless data.empty?
            days=data.keys
            labels=create_labels(days, 5)
            averages=data.values
            miny=averages.min-0.5 unless averages.min<0.4
            maxy=averages.max+0.5
            title=@name+" Grade "+grade.to_s+" "+subject.capitalize+" "+prettify_gender(gender)
            graph=Gruff::Line.new(800)
            graph.title=title
            graph.x_axis_label="Days"
            graph.y_axis_label="Average comprehension"
            graph.minimum_value=miny
            graph.maximum_value=maxy
            graph.y_axis_increment=0.5
            graph.theme={
                :colors => %w(blue red),
                :marker_color => 'grey',
                :font_color => 'black',
                :background_colors => 'white'
            }
            graph.labels=labels
            graph.data("Average Comprehension", averages)
            graph.data("Linear Regression", get_linear_data(averages))
            graph.write(@name+"Graphs/"+filename)
        end
    end

    def prettify_gender(gender)
        gender="Male" if gender=="m"
        gender="Female" if gender=="f"
        gender= "" unless gender
        return gender
    end

    def create_labels(days, percision)
        i=1
        labels={}
        days.each do |day|
            labels[i]=i.to_s if i%percision==0
            i+=1
        end
        return labels
    end

    def get_linear_data(averages)
        xdata=[*1..averages.count]
        ydata=averages
        linefit=LineFit.new
        linefit.setData(xdata, ydata)
        return linefit.predictedYs
    end 

    def get_averages(grade, subject, gender=false)
        averages={}
        @dates.each do |date|
            comp_count=0
            comp_total=0
            @students.each do |student_data|
                comp_level=0
                student=student_data.last
                if gender
                    comp_level=student.get_comp(grade, subject, date) if student.gender==gender
                else
                    comp_level=student.get_comp(grade, subject, date)
                end
                unless comp_level==0
                    comp_count+=1
                    comp_total+=comp_level
                end
            end
            unless comp_count==0
                average=comp_total.to_f/comp_count.to_f
                averages[date]=average
            end
        end
        return averages
    end

    def get_final_comprehension_averages
        grade_2_math_begin, grade_2_math_end = get_subject_grade_comprehension_averages(2,'math')
        grade_4_math_begin, grade_4_math_end = get_subject_grade_comprehension_averages(4,'math')
        grade_2_eng_begin, grade_2_eng_end = get_subject_grade_comprehension_averages(2, 'eng')
        grade_4_eng_begin, grade_4_eng_end = get_subject_grade_comprehension_averages(4, 'eng')
        begin_avg=calculate_total_comprehension_average [grade_4_eng_begin,grade_4_math_begin,grade_2_eng_begin,grade_2_math_begin]
        end_avg= calculate_total_comprehension_average [grade_4_eng_end,grade_4_math_end,grade_2_eng_end,grade_2_math_end]
        return begin_avg, end_avg
    end

    def get_subject_grade_comprehension_averages(grade, subject)
        data=get_averages(grade, subject)
        unless data.empty?
            averages=data.values
            linear=get_linear_data(averages)
            begin_avg=linear.first
            end_avg=linear.last
            return begin_avg, end_avg
        else
            return 0, 0
        end
    end

    def calculate_total_comprehension_average(avg_arrays)
        avg_arrays.reject! {|x| x==0}
        sum=0
        avg_arrays.each do |avg|
            sum+=avg
        end
        length=avg_arrays.count.to_f
        average=sum/length
        return average
    end

end


def generate_comprehension_graph
    schools=["Freeman", "CedarGrove", "Pares", "OldRoad", "SROlivia", "Villa", "Buckleys"]
    i=1
    graph=Gruff::Line.new(800)
    graph.title="Comprehension Comparison"
    graph.y_axis_label="Average Comprehension"
    graph.x_axis_label="Schools"
    graph.theme={
        :colors => %w(green red blue),
        :marker_color => 'grey',
        :font_color => 'black',
        :background_colors => 'white',
    }
    all_averages=[]
    labels={}
    schools.each do |school_name|
        school=School.new(school_name, false)
        begin_average, end_average = school.get_final_comprehension_averages
        ydata=[begin_average, end_average]
        xdata=[i,i]
        all_averages+=ydata
        puts school.name
        puts ydata
        graph.dataxy(school.name, xdata, ydata, get_theme_color(begin_average, end_average))
        labels[i]=school.name
        i+=1

    end
    graph.labels=labels
    graph.minimum_value=all_averages.min-0.2 if all_averages.min > 0.19
    graph.maximum_value=all_averages.max+0.2
    graph.y_axis_increment=0.2
    graph.write("TotalComprehensionAverageGraph.png")
end

def get_theme_color(begin_avg, end_avg)
    return "red" if begin_avg > end_avg
    return "green" if end_avg > begin_avg
    return "grey" 
end
