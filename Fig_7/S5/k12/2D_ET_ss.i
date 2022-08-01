[Mesh]
  [leaky_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 100
    xmin = 0.2 # Well radius
    xmax = 5000
    bias_x = 1.01
    bias_y = 1.1
    ny = 50
    ymin = -100
    ymax = 0
  []
  [aquifer_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 100
    xmin = 0.2 # 1.0035134755011e03Well radius
    xmax = 5000
    bias_x = 1.01
    #bias_y = 0.5
    ny = 5
    ymax = -100
    ymin = -101
  []
  [mesh]
    type = StitchedMeshGenerator
    inputs = 'leaky_mesh aquifer_mesh'
    clear_stitched_boundary_ids = true
    stitch_boundaries_pairs = 'bottom top'
  []
  [leaky]
    type = SubdomainBoundingBoxGenerator
    block_id = 1
    bottom_left = '0.2 -100 0'
    top_right = '10000 0 0'
    input = mesh
  []
  [aquifer]
    type = SubdomainBoundingBoxGenerator
    block_id = 2
    bottom_left = '0.2 -101 0'
    top_right = '10000 -100 0'
    input = leaky
  []
  [injection_area]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x=0.2'
    included_subdomain_ids = 2
    new_sideset_name = 'injection_area'
    input = 'aquifer'
  []
  [left_no_flux]
    type = ParsedGenerateSideset
    combinatorial_geometry = 'x=0.2'
    included_subdomain_ids = 1
    new_sideset_name = 'left_no_flux'
    input = 'injection_area'
  []
[]

[Problem]
  coord_type = RZ
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  PorousFlowDictator = dictator
  biot_coefficient = 1
  multiply_by_density = true
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [porepressure]
  []
[]

[AuxVariables]
  [stress_rr]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_ver]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_tt]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [stress_rr]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_rr
    index_i = 0
    index_j = 0
  []
  [stress_ver]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_ver
    index_i = 1
    index_j = 1
  []
  [stress_tt]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_tt
    index_i = 2
    index_j = 2
  []
[]

[BCs]
  [no_x_disp]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'right injection_area left_no_flux'
  []
  [no_y_disp]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'top'
  []
  [disp_y_bottom]
    type = FunctionDirichletBC
    variable = disp_y
    function = 0
    boundary = 'bottom'
  []
  [pp]
    type = FunctionDirichletBC
    variable = porepressure
    function = 0
    boundary = top
  []
[]

[Modules]
  [FluidProperties]
    [the_simple_fluid]
      type = SimpleFluidProperties
      thermal_expansion = 0.0
      bulk_modulus = 2.0E9
      viscosity = 1E-3
      density0 = 1000.0
    []
  []
[]

[PorousFlowBasicTHM]
  coupling_type = HydroMechanical
  displacements = 'disp_x disp_y'
  porepressure = porepressure
  gravity = '0 -10 0'
  fp = the_simple_fluid
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    bulk_modulus = 1E10
    poissons_ratio = 0.25
  []
  [strain]
    type = ComputeAxisymmetricRZSmallStrain
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [porosity_leaky]
    type = PorousFlowPorosityConst
    porosity = 2
    block = 1
  []
  [porosity_aquifer]
    type = PorousFlowPorosityConst
    porosity = 2
    block = 2
  []
  [biot_modulus]
    type = PorousFlowConstantBiotModulus
    solid_bulk_compliance = 1E-10
    fluid_bulk_modulus = 2.0E9
  []
  [permeability_leaky]
    type = PorousFlowPermeabilityConst
    permeability = '1.0E-11 0 0 0 1.0E-11 0 0 0 1.0E-12'
    block = 1
  []
  [permeability_aquifer]
    type = PorousFlowPermeabilityConst
    permeability = '1.0E-12 0 0 0 1.0E-12 0 0 0 1.0E-12'
    block = 2
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 2000
  []
[]

[Postprocessors]
  [pp_0]
    type = PointValue
    point = '0.2 -101 0'
    variable = porepressure
    execute_on = 'TIMESTEP_END'
  []
  [pp_inf]
    type = PointValue
    point = '4000 -101 0'
    variable = porepressure
    execute_on = 'TIMESTEP_END'
  []
[]


[Preconditioning]
  [lu]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]

[Executioner]
  type = Steady
  solve_type = Newton
[]

[Outputs]
  exodus = true
  csv = true
  file_base = gold/2D_ET_SS
[]
