def export
  result = Patient.find(:all, 
    :joins => 'INNER JOIN patient_identifier id ON patient.patient_id = id.patient_id', 
    :conditions => ["id.identifier = 'NNO 1'"])
  FasterCSV.open("/tmp/file.csv", "w") do |csv|
    result.each do | p |
      process_header(csv, p)
    end
  end
end

def process_header(csv, patient)
  #csv << [patient.arv_number, patient.person.name, patient.gender, patient.person.address, patient.person.birthdate_formatted, patient.person.phone_numbers]
  person_demographics = patient.person.demographics
  csv << [patient.id,
    patient.get_identifier('ARV Number'),
    person_demographics['person']['addresses']['city_village'],
    person_demographics['person']['patient']['identifiers']['National id'],
    person_demographics['person']['names']['given_name'] + ' ' + person_demographics['person']['names']['family_name'],
    person_demographics['person']['gender'],
    patient.person.age,
    person_demographics['person']['occupation'],
    person_demographics['person']['addresses']['city_village'],
    person_demographics['person']['addresses']['location'],
    patient.initial_weight,
    patient.initial_height,
    patient.initial_bmi,
    patient.person.observations.recent(1).question("Agrees to followup").all,
    #visits.agrees_to_followupatient.to_s.split(':')[1].strip rescue nil,
    patient.person.observations.recent(1).question("FIRST POSITIVE HIV TEST DATE").all,
    #visits.hiv_test_date.to_s.split(':')[1].strip rescue nil,
    patient.person.observations.recent(1).question("FIRST POSITIVE HIV TEST LOCATION").all,
    #visits.hiv_test_location.to_s.split(':')[1].strip rescue nil,
    patient.person.relationships.map{|r|Person.find(r.person_b).name}.join(' : '),
    patient.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all,
    #visits.reason_for_art_eligibility.map{|c|ConceptName.find(c.value_coded_name_id).name}.join(','),
    patient.person.observations.recent(1).question("HAS TRANSFER LETTER").all
    #visits.transfer_in.blank? == true ? visits.transfer_in = 'NO' : visits.transfer_in = 'YES'
  ]
end

