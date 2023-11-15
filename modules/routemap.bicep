param routemapname string
param associatedInboundConnections array = []
param associatedOutboundConnections array = []
param rulename string
param matchcriteria_asPath array = []
param matchcriteria_community array = []
param matchcriteria_prefix array = []
param matchCondition string = ''
param action_asPath array = []
param action_community array = []
param action_prefix array  = []
param action_type string = ''
param nextStepIfMatched string

resource routemap 'Microsoft.Network/virtualHubs/routeMaps@2023-04-01' = {
  name: routemapname
  properties: {
    rules: [
      {
        name: rulename
        matchCriteria: [
          {
            asPath: matchcriteria_asPath != [] ? matchcriteria_asPath : []
            community: matchcriteria_community != [] ? matchcriteria_community : []
            routePrefix: matchcriteria_prefix != [] ? matchcriteria_prefix : []
            matchCondition: matchCondition
          }
        ]
        actions: [
          {
            parameters: [
              {
                asPath: action_asPath != [] ? action_asPath : []
                community: action_community != [] ? action_community : []
                routePrefix: action_prefix != [] ? action_prefix : []
              }
            ]
            type: action_type
          }
        ]
        nextStepIfMatched: nextStepIfMatched
      }
    ]
    associatedInboundConnections: associatedInboundConnections != [] ? associatedInboundConnections : []
    associatedOutboundConnections: associatedOutboundConnections != [] ? associatedOutboundConnections : []
  }
}
