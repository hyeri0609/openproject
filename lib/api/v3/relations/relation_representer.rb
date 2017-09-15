#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Relations
      class RelationRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        link :self do
          { href: api_v3_paths.relation(represented.id) }
        end

        link :updateImmediately do
          if manage_relations?
            { href: api_v3_paths.relation(represented.id), method: :patch }
          end
        end

        link :delete do
          if manage_relations?
            {
              href: api_v3_paths.relation(represented.id),
              method: :delete,
              title: 'Remove relation'
            }
          end
        end

        property :id

        property :name, exec_context: :decorator

        property :relation_type, as: :type

        property :reverse_type, as: :reverseType, exec_context: :decorator

        ##
        # The `delay` property is only used for the relation type "precedes/follows".
        property :delay,
                 render_nil: true,
                 if: ->(*) {
                   # the relation type may be blank when parsing for an update
                   [Relation::TYPE_FOLLOWS, Relation::TYPE_PRECEDES].include?(relation_type) ||
                     relation_type.blank?
                 }

        property :description, render_nil: true

        associated_resource :ancestor,
                            as: :from,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter,
                            link_title_attribute: :subject,
                            setter: associated_resource_default_setter(:from,
                                                                       :ancestor,
                                                                       :work_package),
                            getter: associated_resource_default_getter(:ancestor,
                                                                       ::API::V3::WorkPackages::WorkPackageRepresenter),
                            link: associated_resource_default_link(:from,
                                                                   :work_package,
                                                                   -> { false },
                                                                   :subject)

        associated_resource :descendant,
                            as: :to,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter,
                            link_title_attribute: :subject,
                            setter: associated_resource_default_setter(:to,
                                                                       :descendant,
                                                                       :work_package),
                            getter: associated_resource_default_getter(:descendant,
                                                                       ::API::V3::WorkPackages::WorkPackageRepresenter),
                            link: associated_resource_default_link(:to,
                                                                   :work_package,
                                                                   -> { false },
                                                                   :subject)

        def _type
          @_type ||= "Relation"
        end

        def _type=(_type)
          # readonly
        end

        def name
          I18n.t "label_#{represented.relation_type}"
        end

        def name=(name)
          # readonly
        end

        def reverse_type
          represented.reverse_type
        end

        def reverse_type=(reverse_type)
          # readonly
        end

        def manage_relations?
          current_user_allowed_to :manage_work_package_relations, context: represented.ancestor.project
        end

        self.to_eager_load = [:descendant,
                              ancestor: { project: :enabled_modules }]
      end
    end
  end
end
