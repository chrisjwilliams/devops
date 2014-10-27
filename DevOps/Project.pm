package DevOps::Project;
use strict;
use DevOps::EnvironmentManager;
use DevOps::DependencyManager;
use DevOps::Source;
use Paf::Configuration::XmlFile;
use Paf::Configuration::NodeFilter;
use Carp;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;

    $self->{id} = defined($_[0])? shift : die "no id provided";
    $self->{location} = defined($_[0])? shift : die "no location specified";

    $self->{project_file}=$self->{location}."/project.devops";
    $self->{config}=Paf::Configuration::XmlFile->new($self->{project_file});
    ($self->{node})=$self->{config}->root()->search(new Paf::Configuration::NodeFilter("DevOps", { type => "project" }));
    if( !defined $self->{node} ) {
        $self->{node}=$self->{config}->root()->new_child("DevOps", { type => "project" } );
        $self->{node}->add_meta("version", "0.0.0");
    }
    
    if( ! defined $self->devops_version() ) { die ("must specify <DevOps version=\"0.0.0\"> in ", $self->{project_file}); }

    # DependencyManager
    my $dep_config=$self->{node}->get_child(new Paf::Configuration::NodeFilter("dependencies"));
    $self->{deps}=DevOps::DependencyManager->new($dep_config);

    # EnvironmentManager
    my $env_config=$self->{node}->get_child(new Paf::Configuration::NodeFilter("EnvironmentManager"));
    $self->{env}=DevOps::EnvironmentManager->new($env_config);

    # -- task management node structure
    (my $node)=$self->{node}->search(new Paf::Configuration::NodeFilter("workflows"));
    if(!defined $node) { $node=$self->{node}->new_child("workflows"); }
    ($self->{workflows}{build})=$node->search(new Paf::Configuration::NodeFilter("workflow", { name => "build" }));
    if(!defined $self->{workflows}{build}) { $self->{workflows}{build}=$node->new_child("workflow", { name => "build"} ); }

    $self->_load_sources();

    # -- default environments
    my $default_env=DevOps::Environment->new( { library_dir => "/usr/lib",
                                                include_dir => "/usr/include",
                                                install_dir => "" } );
#    $self->{env}->add("module", $default_env);

    return $self;
}

sub devops_version {
    my $self=shift;
    return $self->{node}->meta()->{version};
}

sub id {
    my $self=shift;
    return $self->{id};
}

sub name {
    my $self=shift;
    return $self->{id}->name();
}

sub version {
    my $self=shift;
    return $self->{id}->version();
}

sub add_sources {
    my $self=shift;
    foreach my $src (@_) {
        if( ! defined $src->sub_dir() ) {
            $self->{src_top}=$src;
        }
        else {
            $self->{srcs}{$src->sub_dir()}=$src;
        }
    }
}

sub remove_sources {
    my $self=shift;
    foreach my $src (@_) {
        if( ! defined $src->sub_dir() ) {
            delete $self->{src_top};
        }
        else {
            delete $self->{srcs}{$src->sub_dir()};
        }
    }
    
}

sub sources {
    my $self=shift;
    my @sources=values %{$self->{srcs}};
    if(defined $self->{src_top}) {
        unshift @sources, $self->{src_top};
    }
    return @sources;
}

sub location {
    my $self=shift;
    return $self->{location};
}

sub add_dependency {
    my $self=shift;
    $self->{deps}->add(@_);
}

sub add_dependencies {
    my $self=shift;
    $self->{deps}->add_dependencies(@_);
}

sub remove_dependencies {
    my $self=shift;
    $self->{deps}->remove_dependencies(@_);
}

sub dependencies {
    my $self=shift;
    return $self->{deps}->dependencies();
}

sub has_dependency {
    my $self=shift;
    return $self->{deps}->has_dependency(@_);
}

sub environment {
    my $self=shift;
    return $self->{env}->environment(@_);
}

sub add_environment {
    my $self=shift;
    return $self->{env}->add(@_);
}

# -- workflow descriptions ---

# @brief return the code associated with a specific workflow task.
#
#        variants and platform specific tasks are supported.
#        The code will be exapnded if there are any task variables 
#        defined.
#
sub task_code {
    my $self=shift;
    my $workflow=shift || carp ("workflow name unspecified");
    my $task_name=shift || carp ("task_name unspecified");
    my $platform=shift; # optional - use undef
    my $variant=shift;  # optional - use undef

    my $task_node=$self->_task_node($workflow, $task_name);

    # read in any workspace scoped environments, and task specific environments
    my $env=DevOps::Environment->new();
    foreach my $env_filter ( $self->_variant_sections("env", $platform, $variant), new Paf::Configuration::NodeFilter("environment", {}) )
    {
        my @envs= $task_node->search($env_filter), $self->{workflows}{$workflow}->search($env_filter);
        next, unless @envs;
        foreach my $e ( @envs ) {
            my $var_block=new DevOps::Configuration::VariableBlock($e);
            $env->merge(new DevOps::Environment($var_block->vars()));
        }
    }

    foreach my $filter ( $self->_variant_sections("code", $platform, $variant) )
    {
        my @actions=$task_node->search($filter);
        next, unless @actions;

        # -- best matching section found
        # -- expand variables in the commands and we are done
        my @code;
        my $action=$actions[0];
        foreach my $line ( @{$action->content()} ) {
            my $exline=$env->expandString($line);
            push @code, $exline;
        }
        return @code;
    }
    return ();
}

# @brief set the code to be associated with a specific workflow task.
#        optionally variants and platforms are supported.
sub add_task_code {
    my $self=shift;
    my $workflow=shift;
    my $task_name=shift;
    my $platform=shift; # optional - use undef
    my $variant=shift;  # optional - use undef

    my $task_node=$self->_task_node($workflow, $task_name);

    # -- store in the most specialized section
    (my $section)=$self->_variant_sections("code", $platform, $variant);
    (my $node)=$task_node->search($section);
    if(!defined $node) { $node=$task_node->new_child("code", $section->meta()); }
    $node->add_content(@_);
}

sub _task_node {
    my $self=shift;
    my $workflow=shift;
    my $task_name=shift;

    die "unknown workflow $workflow", if( ! defined $self->{workflows}{$workflow} );
    (my $node)=$self->{workflows}{$workflow}->search(new Paf::Configuration::NodeFilter("task", { name => $task_name } ));
    if(! defined $node ) {
        $node=$self->{workflows}{$workflow}->new_child("task", { name => $task_name });
    }
    return $node;
}

#
# create a list of search filters for different variants
#
sub _variant_sections {
    my $self=shift;
    my $base=shift || die ("expecting a base tag name");
    my $platform=shift; # optional
    my $variants=shift; # optional

    my @list=( new Paf::Configuration::NodeFilter($base) );
    my @outer_list=( {} );
    if( defined $platform ) {
        my $filter=new Paf::Configuration::NodeFilter($base, { arch => $platform->arch() });
        push @outer_list, $filter->meta();
        unshift @list, $filter; 
    }
    foreach my $search ( @outer_list ) {
        foreach my $key ( sort keys %{$variants} ) {
            $search->{$key}=join("_", sort(@{$variants->{$key}}));
            unshift @list, new Paf::Configuration::NodeFilter($base, $search);
        }
    }
    return @list;
}

sub save {
    my $self=shift;

    $self->_sync_config();
    $self->{config}->save();
}

sub save_to_location {
    my $self=shift;
    my $loc=shift;

    $self->_sync_config();
    $self->{config}->save($loc."/project.devops");
}

sub _sync_config {
    my $self=shift;

    $self->{env}->save();
    $self->{deps}->save();

    # -- save sources
    my $node=$self->{node}->get_child(new Paf::Configuration::NodeFilter("sources"));
    $node->reset();

    foreach my $src ( $self->sources() ) {
        my $source_node=$node->new_child("source", $src->vcs_config());
        
        if( defined $src->sub_dir()) { 
            $source_node->meta()->{sub_dir}=$src->sub_dir();
        }
        if( defined $src->vcs_type()) { 
            $source_node->meta()->{type}=$src->vcs_type();
        }
        if( defined $src->version()) { 
            $source_node->meta()->{version}=$src->version();
        }
    }
}

sub _load_sources {
    my $self=shift;

    (my $node)=$self->{node}->search(new Paf::Configuration::NodeFilter("sources"));
    return, if ( ! defined $node );
    
    # -- load sources
    foreach my $section ( $node->search(new Paf::Configuration::NodeFilter("source")) ) { # ensure any without a sub_dir is first to ensure dir is built
        my $sub_dir=$section->meta()->{sub_dir};
        my $vcs_type=$section->meta()->{"type"};
        my $vcs_version=$section->meta()->{"version"};
        my $vcs_config=$section->meta();
        delete $vcs_config->{"sub_dir"};
        delete $vcs_config->{"type"};
        delete $vcs_config->{"version"};

        $self->add_sources(new DevOps::Source($sub_dir, $vcs_type, $vcs_config, $vcs_version));
    }
}
