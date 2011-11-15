class ConceptVisualizerController < ApplicationController

  
  def visualize
    @visited_concepts = []
    @touched_concepts = []

    # configs
    #excluded_concepts = [6234, 6322, 6324, 6325, 6326, 6327, 6323]
    @max_concept_length = 50

      concept_id = params[:concept_id]
      create_dot [Concept.find(concept_id)], 'concept.dot', [], 1
      create_svg 'concept.dot', 'concept.svg'
      send_file ("concept.svg", :type=>"image/svg+xml", :disposition=>"inline")
#send_file '/Users/xian/projects/pih/openmrs-concept-dictionary-visualizer/opd_diagnosis.svg', :type=>"image/svg+xml", :disposition=>"inline" 

  end

  def concept_name(c)
    return "#{c.concept_names.first.name[0..@max_concept_length]} (#{c.concept_id})"
  end

  def print_edges(c, f, excluded_concepts, max_depth = 10)
    max_depth = max_depth - 1
  	@touched_concepts.push(c)

    if !c.retired? && max_depth >= 0 && @visited_concepts.index(c.concept_id) == nil && excluded_concepts.index(c.concept_id) == nil
    	@visited_concepts.push(c.concept_id)
      name = c.concept_id

      # answers
      c.concept_answers.each do |a| 
        begin
          answer = Concept.find(a.answer_concept)
          if !answer.retired? && excluded_concepts.index(answer.id) == nil
            answer_name = answer.concept_id
            f.puts "  \"#{name}\" -- \"#{answer_name}\" [color=red];"
            print_edges(answer, f, excluded_concepts, max_depth)
          end
        rescue
          f.puts "  \"#{name}\" -- \"Retired concepts\" [color=blue];"
        end
      end

      # questions
      ConceptAnswer.find_all_by_answer_concept(c.id).each do |q|
        begin
          question = Concept.find(q.concept_id)
          if !question.retired? && excluded_concepts.index(question.id) == nil
            question_name = question.concept_id
            f.puts "  \"#{name}\" -- \"#{question_name}\" [color=red];"
            # only one hierarchy
            print_edges(question, f, excluded_concepts, max_depth)
          end
        rescue
          f.puts "  \"#{name}\" -- \"Retired concepts\" [color=blue];"
        end
      end

      # concept sets
      sets = ConceptSet.find_all_by_concept_id(c.id)
      sets.each do |s|
        begin
          set = Concept.find(s.concept_set)
          if !set.retired? && excluded_concepts.index(set.id) == nil
            set_name = set.concept_id
            f.puts "  \"#{set_name}\" -- \"#{name}\" [color=red];"
            print_edges(set, f, excluded_concepts, max_depth)
          end
        rescue
          f.puts "  \"#{name}\" -- \"Retired concepts\" [color=blue];"
        end
      end

      # concept set members
      sets = ConceptSet.find_all_by_concept_set(c.id)
      sets.each do |s| 
        begin
          member = Concept.find(s.concept_id)
          if !member.retired? && excluded_concepts.index(member.id) == nil
            member_name = member.concept_id
            f.puts "  \"#{member_name}\" -- \"#{name}\" [color=red];"
            print_edges(member, f, excluded_concepts, max_depth)
          end
        rescue
          f.puts "  \"#{name}\" -- \"Retired concepts\" [color=blue];"
        end
      end
    end
  end

  def print_nodes(f)
    @touched_concepts.each do |c|
      f.puts "  \"#{c.concept_id}\" [ label=\"#{concept_name(c)}\", href=\"http://localhost:3000/concept_visualizer/visualize?concept_id=#{c.concept_id}\"];"
    end
  end

  def create_dot(concepts, dot_filename, excluded_concepts, max_depth)
    f = File.open(dot_filename, 'w')
    f.puts "strict graph opd {"
    #f.puts "  rotate=90;"

    concepts.each do |c|
      print_edges(c, f, excluded_concepts, max_depth)
    end
    print_nodes f

    f.puts "  ranksep = #{@touched_concepts.size / 10};"
    f.puts "}"
    f.close
  end

  def create_svg(dot_filename, svg_filename)
    `ccomps -x #{dot_filename} | dot | gvpack -g | twopi -Tsvg -n2 -s > #{svg_filename}`
   # `dot -Tsvg -o #{svg_filename} #{dot_filename}`
  #`./create_svg.sh opd_diagnosis.svg opd_diagnosis.dot`
  end


  # graph whole dictionary
  #create_svg Concept.find(:all), 'whole_dictionary.dot', [], 1

  # start from one concept, OPD diagnosis

  # start from chosen ones
  #[7072, 7073, 7074, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7085].each do |c|
  #  print_edges Concept.find(c), f, excluded_concepts, 3
  #end


end
