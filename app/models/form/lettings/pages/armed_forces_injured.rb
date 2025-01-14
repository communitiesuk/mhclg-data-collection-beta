class Form::Lettings::Pages::ArmedForcesInjured < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "armed_forces_injured"
    @depends_on = [{ "armedforces" => 1 }, { "armedforces" => 4 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::Reservist.new(nil, nil, self)]
  end
end
