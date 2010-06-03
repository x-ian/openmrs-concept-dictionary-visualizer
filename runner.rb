

def print_concept(c, f, excluded_concepts, recursive = true, max_level = 1000)
  max_concept_length = 50
  max_level = max_level - 1

  if !c.retired? && max_level >= 0
    name = c.name.name[0..max_concept_length]
    # answers
    c.concept_answers.each do |a|
      answer = Concept.find(a.answer_concept)
      if !answer.retired? && excluded_concepts.index(answer.id) == nil
        answer_name = answer.name.name #[0..max_concept_length]
        f.puts "  \"#{name}\" -- \"#{answer_name}\" [color=red];"
        print_concept(answer, f, excluded_concepts, recursive, max_level) if recursive
      end
    end
    # questions
    ConceptAnswer.find_all_by_answer_concept(c.id).each do |q|
      question = Concept.find(q.concept_id)
      if !question.retired? && excluded_concepts.index(question.id) == nil
        question_name = question.name.name[0..max_concept_length]
        f.puts "  \"#{name}\" -- \"#{question_name}\" [color=red];"
        # only one hierarchy
        print_concept(question, f, excluded_concepts, recursive, max_level) if recursive
      end
    end
    # concept sets
    sets = ConceptSet.find_all_by_concept_id(c.id)
    sets.each do |s|
      set = Concept.find(s.concept_set)
      if !set.retired? && excluded_concepts.index(set.id) == nil
        set_name = set.name.name[0..max_concept_length]
        f.puts "  \"#{set_name}\" -- \"#{name}\" [color=blue];"
        print_concept(set, f, excluded_concepts, recursive, max_level) if recursive
      end
    end
    # concept set members
    sets = ConceptSet.find_all_by_concept_set(c.id)
    sets.each do |s|
      set = Concept.find(s.concept_id)
      if !set.retired? && excluded_concepts.index(set.id) == nil
        set_name = set.name.name[0..max_concept_length]
        f.puts "  \"#{set_name}\" -- \"#{name}\" [color=blue];"
        print_concept(set, f, excluded_concepts, recursive, max_level) if recursive
      end
    end
  end
end

f = File.open('dictionary.dot', 'w')
f.puts "strict graph opd {"
f.puts "  rankdir = LR;"
#f.puts "  rotate=90;"

excluded_concepts = [6234, 6322, 6324, 6325, 6326, 6327, 6323]

# graph whole dictionary
#concepts = Concept.find(:all).each do |c|
#  print_concept(c, f, excluded_concepts, false)
#end

# start from one concept
#print_concept Concept.find(3065), f, excluded_concepts, true

# start from chosen ones
[7072, 7073, 7074, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7085].each do |c|
  print_concept Concept.find(c), f, excluded_concepts, true, 3
end

f.puts "}"

#/var/www/mateme_jeff/mateme/script/runner runner.rb
# dot -Tsvg -o dictionary.svg dictionary.dot
#ccomps -x opd | dot | gvpack -g | neato -Tsvg -n2 -s > opd.svg
